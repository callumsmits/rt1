//
//  prefixSumScan.m
//  rt1
//
//  Created by Callum Smits on 16/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "prefixSumScan.h"
#include <libc.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach/mach_time.h>
#include <math.h>
#include "globalSettings.h"

#include <OpenCL/opencl.h>

#define DEBUG_INFO      (0)
int		GROUP_SIZE      = 256;
#define NUM_BANKS       (16)
#define MAX_ERROR       (1e-7)
#define SEPARATOR       ("----------------------------------------------------------------------\n")

#define min(A,B) ((A) < (B) ? (A) : (B))

enum KernelMethods
{
    PRESCAN                             = 0,
    PRESCAN_STORE_SUM                   = 1,
    PRESCAN_STORE_SUM_NON_POWER_OF_TWO  = 2,
    PRESCAN_NON_POWER_OF_TWO            = 3,
    UNIFORM_ADD                         = 4
};

static const char* KernelNames[] =
{
    "PreScanKernel",
    "PreScanStoreSumKernel",
    "PreScanStoreSumNonPowerOfTwoKernel",
    "PreScanNonPowerOfTwoKernel",
    "UniformAddKernel"
};

static const unsigned int KernelCount = sizeof(KernelNames) / sizeof(char *);

static char *
LoadProgramSourceFromFile(const char *filename)
{
    struct stat statbuf;
    FILE        *fh;
    char        *source;
    
    fh = fopen(filename, "r");
    if (fh == 0)
        return 0;
    
    stat(filename, &statbuf);
    source = (char *) malloc(statbuf.st_size + 1);
    fread(source, statbuf.st_size, 1, fh);
    source[statbuf.st_size] = '\0';
    
    return source;
}

bool IsPowerOfTwo(int n)
{
    return ((n&(n-1))==0) ;
}

int floorPow2(int n)
{
    int exp;
    frexp((float)n, &exp);
    return 1 << (exp - 1);
}

@interface prefixSumScan () {
    cl_device_id            ComputeDeviceId;
    cl_command_queue        ComputeCommands;
    cl_context              ComputeContext;
    cl_program              ComputeProgram;
    cl_kernel*              ComputeKernels;
    cl_mem*                 ScanPartialSums;
    unsigned int            ElementsAllocated;
    unsigned int            LevelsAllocated;
}

@end

@implementation prefixSumScan

- (int)CreatePartialSumBuffers:(unsigned int) count
{
    ElementsAllocated = count;
    
    unsigned int group_size = GROUP_SIZE;
    unsigned int element_count = count;
    
    int level = 0;
    
    do
    {
        unsigned int group_count = (int)fmax(1, (int)ceil((float)element_count / (2.0f * group_size)));
        if (group_count > 1)
        {
            level++;
        }
        element_count = group_count;
        
    } while (element_count > 1);
    
    ScanPartialSums = (cl_mem*) malloc(level * sizeof(cl_mem));
    LevelsAllocated = level;
    memset(ScanPartialSums, 0, sizeof(cl_mem) * level);
    
    element_count = count;
    level = 0;
    
    do
    {
        unsigned int group_count = (int)fmax(1, (int)ceil((float)element_count / (2.0f * group_size)));
        if (group_count > 1)
        {
            size_t buffer_size = group_count * sizeof(uint);
            ScanPartialSums[level++] = clCreateBuffer(ComputeContext, CL_MEM_READ_WRITE, buffer_size, NULL, NULL);
        }
        
        element_count = group_count;
        
    } while (element_count > 1);
    
    return CL_SUCCESS;
}

- (void)ReleasePartialSums
{
    unsigned int i;
    for (i = 0; i < LevelsAllocated; i++)
    {
        clReleaseMemObject(ScanPartialSums[i]);
    }
    
    free(ScanPartialSums);
    ScanPartialSums = 0;
    ElementsAllocated = 0;
    LevelsAllocated = 0;
}

- (int)PrescanGlobal:(size_t *)global local:(size_t *)local shared:(size_t)shared outputData:(cl_mem)output_data intputData:(cl_mem)input_data n:(unsigned int)n groupIndex:(int)group_index base_index:(int)base_index
{
#if DEBUG_INFO
    printf("PreScan: Global[%4d] Local[%4d] Shared[%4d] BlockIndex[%4d] BaseIndex[%4d] Entries[%d]\n",
           (int)global[0], (int)local[0], (int)shared, group_index, base_index, n);
#endif
    
    unsigned int k = PRESCAN;
    unsigned int a = 0;
    
    int err = CL_SUCCESS;
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &output_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &input_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, shared,         0);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &group_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &base_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &n);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to set kernel arguments!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    err = CL_SUCCESS;
    err |= clEnqueueNDRangeKernel(ComputeCommands, ComputeKernels[k], 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to execute kernel!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    return CL_SUCCESS;
}

- (int)PreScanStoreSumGlobal:(size_t *)global local:(size_t *)local shared:(size_t)shared outputData:(cl_mem)output_data intputData:(cl_mem)input_data partialSums:(cl_mem)partial_sums n:(unsigned int)n groupIndex:(int)group_index base_index:(int)base_index
{
#if DEBUG_INFO
    printf("PreScan: Global[%4d] Local[%4d] Shared[%4d] BlockIndex[%4d] BaseIndex[%4d] Entries[%d]\n",
           (int)global[0], (int)local[0], (int)shared, group_index, base_index, n);
#endif
    
    unsigned int k = PRESCAN_STORE_SUM;
    unsigned int a = 0;
    
    int err = CL_SUCCESS;
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &output_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &input_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &partial_sums);
    err |= clSetKernelArg(ComputeKernels[k],  a++, shared,         0);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &group_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &base_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &n);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to set kernel arguments!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    err = CL_SUCCESS;
    err |= clEnqueueNDRangeKernel(ComputeCommands, ComputeKernels[k], 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to execute kernel!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    return CL_SUCCESS;
}

- (int)PreScanStoreSumNonPowerOfTwo:(size_t *)global local:(size_t *)local shared:(size_t)shared outputData:(cl_mem)output_data intputData:(cl_mem)input_data partialSums:(cl_mem)partial_sums n:(unsigned int)n groupIndex:(int)group_index base_index:(int)base_index
{
#if DEBUG_INFO
    printf("PreScanStoreSumNonPowerOfTwo: Global[%4d] Local[%4d] BlockIndex[%4d] BaseIndex[%4d] Entries[%d]\n",
           (int)global[0], (int)local[0], group_index, base_index, n);
#endif
    
    unsigned int k = PRESCAN_STORE_SUM_NON_POWER_OF_TWO;
    unsigned int a = 0;
    
    int err = CL_SUCCESS;
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &output_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &input_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &partial_sums);
    err |= clSetKernelArg(ComputeKernels[k],  a++, shared,         0);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &group_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &base_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &n);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to set kernel arguments!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    err = CL_SUCCESS;
    err |= clEnqueueNDRangeKernel(ComputeCommands, ComputeKernels[k], 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to execute kernel!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    return CL_SUCCESS;
}

- (int)PreScanNonPowerOfTwo:(size_t *)global local:(size_t *)local shared:(size_t)shared outputData:(cl_mem)output_data intputData:(cl_mem)input_data n:(unsigned int)n groupIndex:(int)group_index base_index:(int)base_index
{
#if DEBUG_INFO
    printf("PreScanNonPowerOfTwo: Global[%4d] Local[%4d] BlockIndex[%4d] BaseIndex[%4d] Entries[%d]\n",
           (int)global[0], (int)local[0], group_index, base_index, n);
#endif
    
    unsigned int k = PRESCAN_NON_POWER_OF_TWO;
    unsigned int a = 0;
    
    int err = CL_SUCCESS;
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &output_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &input_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, shared,         0);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &group_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &base_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &n);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to set kernel arguments!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    err = CL_SUCCESS;
    err |= clEnqueueNDRangeKernel(ComputeCommands, ComputeKernels[k], 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to execute kernel!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    return CL_SUCCESS;
}

- (int)UniformAdd:(size_t *)global local:(size_t *)local outputData:(cl_mem)output_data partialSums:(cl_mem)partial_sums n:(unsigned int)n groupOffset:(int)group_offset base_index:(int)base_index
{
#if DEBUG_INFO
    printf("UniformAdd: Global[%4d] Local[%4d] BlockOffset[%4d] BaseIndex[%4d] Entries[%d]\n",
           (int)global[0], (int)local[0], group_offset, base_index, n);
#endif
    
    unsigned int k = UNIFORM_ADD;
    unsigned int a = 0;
    
    int err = CL_SUCCESS;
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &output_data);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_mem), &partial_sums);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(uint),  0);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &group_offset);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &base_index);
    err |= clSetKernelArg(ComputeKernels[k],  a++, sizeof(cl_int), &n);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to set kernel arguments!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    err = CL_SUCCESS;
    err |= clEnqueueNDRangeKernel(ComputeCommands, ComputeKernels[k], 1, NULL, global, local, 0, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        printf("Error: %s: Failed to execute kernel!\n", KernelNames[k]);
        return EXIT_FAILURE;
    }
    
    return CL_SUCCESS;
}

- (int)PreScanBufferRecursive:(cl_mem)output_data inputData:(cl_mem)input_data maxGroupSize:(int)max_group_size maxWorkItemCount:(int)max_work_item_count elementCount:(int)element_count level:(int)level
{
    unsigned int group_size = max_group_size;
    unsigned int group_count = (int)fmax(1.0f, (int)ceil((float)element_count / (2.0f * group_size)));
    unsigned int work_item_count = 0;
    
    if (group_count > 1)
        work_item_count = group_size;
    else if (IsPowerOfTwo(element_count))
        work_item_count = element_count / 2;
    else
        work_item_count = floorPow2(element_count);
    
    work_item_count = (work_item_count > max_work_item_count) ? max_work_item_count : work_item_count;
    
    unsigned int element_count_per_group = work_item_count * 2;
    unsigned int last_group_element_count = element_count - (group_count-1) * element_count_per_group;
    unsigned int remaining_work_item_count = (int)fmax(1.0f, last_group_element_count / 2);
    remaining_work_item_count = (remaining_work_item_count > max_work_item_count) ? max_work_item_count : remaining_work_item_count;
    unsigned int remainder = 0;
    size_t last_shared = 0;
    
    
    if (last_group_element_count != element_count_per_group)
    {
        remainder = 1;
        
        if(!IsPowerOfTwo(last_group_element_count))
            remaining_work_item_count = floorPow2(last_group_element_count);
        
        remaining_work_item_count = (remaining_work_item_count > max_work_item_count) ? max_work_item_count : remaining_work_item_count;
        unsigned int padding = (2 * remaining_work_item_count) / NUM_BANKS;
        last_shared = sizeof(uint) * (2 * remaining_work_item_count + padding);
    }
    
    remaining_work_item_count = (remaining_work_item_count > max_work_item_count) ? max_work_item_count : remaining_work_item_count;
    size_t global[] = { (int)fmax(1, group_count - remainder) * work_item_count, 1 };
    size_t local[]  = { work_item_count, 1 };
    
    unsigned int padding = element_count_per_group / NUM_BANKS;
    size_t shared = sizeof(uint) * (element_count_per_group + padding);
    
    cl_mem partial_sums = ScanPartialSums[level];
    int err = CL_SUCCESS;
    
    if (group_count > 1)
    {
        err = [self PreScanStoreSumGlobal:global local:local shared:shared outputData:output_data intputData:input_data partialSums:partial_sums n:work_item_count * 2 groupIndex:0 base_index:0];
//        err = PreScanStoreSum(global, local, shared, output_data, input_data, partial_sums, work_item_count * 2, 0, 0);
        if(err != CL_SUCCESS)
            return err;
        
        if (remainder)
        {
            size_t last_global[] = { 1 * remaining_work_item_count, 1 };
            size_t last_local[]  = { remaining_work_item_count, 1 };
            
            err = [self PreScanStoreSumNonPowerOfTwo:last_global local:last_local shared:last_shared outputData:output_data intputData:input_data partialSums:partial_sums n:last_group_element_count groupIndex:group_count - 1 base_index:element_count - last_group_element_count];
//            err = PreScanStoreSumNonPowerOfTwo(
//                                               last_global, last_local, last_shared,
//                                               output_data, input_data, partial_sums,
//                                               last_group_element_count,
//                                               group_count - 1,
//                                               element_count - last_group_element_count);
            
            if(err != CL_SUCCESS)
                return err;
			
        }
        
        err = [self PreScanBufferRecursive:partial_sums inputData:partial_sums maxGroupSize:max_group_size maxWorkItemCount:max_work_item_count elementCount:group_count level:level + 1];
//        err = PreScanBufferRecursive(partial_sums, partial_sums, max_group_size, max_work_item_count, group_count, level + 1);
        if(err != CL_SUCCESS)
            return err;
        
        err = [self UniformAdd:global local:local outputData:output_data partialSums:partial_sums n:element_count - last_group_element_count groupOffset:0 base_index:0];
//        err = UniformAdd(global, local, output_data, partial_sums,  element_count - last_group_element_count, 0, 0);
        if(err != CL_SUCCESS)
            return err;
        
        if (remainder)
        {
            size_t last_global[] = { 1 * remaining_work_item_count, 1 };
            size_t last_local[]  = { remaining_work_item_count, 1 };
            
            err = [self UniformAdd:last_global local:last_local outputData:output_data partialSums:partial_sums n:last_group_element_count groupOffset:group_count - 1 base_index:element_count - last_group_element_count];
//            err = UniformAdd(
//                             last_global, last_local,
//                             output_data, partial_sums,
//                             last_group_element_count,
//                             group_count - 1,
//                             element_count - last_group_element_count);
            
            if(err != CL_SUCCESS)
                return err;
        }
    }
    else if (IsPowerOfTwo(element_count))
    {
        err = [self PrescanGlobal:global local:local shared:shared outputData:output_data intputData:input_data n:work_item_count * 2 groupIndex:0 base_index:0];
//        err = PreScan(global, local, shared, output_data, input_data, work_item_count * 2, 0, 0);
        if(err != CL_SUCCESS)
            return err;
    }
    else
    {
        err = [self PreScanNonPowerOfTwo:global local:local shared:shared outputData:output_data intputData:input_data n:element_count groupIndex:0 base_index:0];
//        err = PreScanNonPowerOfTwo(global, local, shared, output_data, input_data, element_count, 0, 0);
        if(err != CL_SUCCESS)
            return err;
    }
    
    return CL_SUCCESS;
}

- (void)PreScanBuffer:(cl_mem)output_data inputData:(cl_mem)input_data maxGroupSize:(unsigned int)max_group_size maxWorkItemCount:(unsigned int)max_work_item_count elementCount:(unsigned int)element_count
{
    [self CreatePartialSumBuffers:element_count];
//    CreatePartialSumBuffers(element_count);
//    PreScanBufferRecursive(output_data, input_data, max_group_size, max_work_item_count, element_count, 0);
    [self PreScanBufferRecursive:output_data inputData:input_data maxGroupSize:max_group_size maxWorkItemCount:max_work_item_count elementCount:element_count level:0];
//    ReleasePartialSums();
    [self ReleasePartialSums];
    clFinish(ComputeCommands);
}

- (bool)initPreScan:(cl_device_id)device queue:(cl_command_queue)queue context:(cl_context)context wgs:(int)wgs {
//bool initPreScan(cl_device_id device, cl_command_queue queue, cl_context context, int wgs) {
    
    NSString *clRootPath = @kRenderCLKernelsPath;
    char *source = LoadProgramSourceFromFile([[clRootPath stringByAppendingString:@"scan_kernel.cl"] cStringUsingEncoding:NSUTF8StringEncoding]);
    if(!source)
    {
        printf("Error: Failed to load compute program from file!\n");
        return EXIT_FAILURE;
    }
    
    ComputeDeviceId = device;
    ComputeContext = context;
    ComputeCommands = queue;
    // Create the compute program from the source buffer
    //
    int err, i;
    ComputeProgram = clCreateProgramWithSource(ComputeContext, 1, (const char **) & source, NULL, &err);
    if (!ComputeProgram || err != CL_SUCCESS)
    {
        printf("%s\n", source);
        printf("Error: Failed to create compute program!\n");
        return EXIT_FAILURE;
    }
    
    // Build the program executable
    //
    err = clBuildProgram(ComputeProgram, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS)
    {
        size_t length;
        char build_log[2048];
        printf("%s\n", source);
        printf("Error: Failed to build program executable!\n");
        clGetProgramBuildInfo(ComputeProgram, ComputeDeviceId, CL_PROGRAM_BUILD_LOG, sizeof(build_log), build_log, &length);
        printf("%s\n", build_log);
        return EXIT_FAILURE;
    }
    
    ComputeKernels = (cl_kernel*) malloc(KernelCount * sizeof(cl_kernel));
    for(i = 0; i < KernelCount; i++)
    {
        // Create each compute kernel from within the program
        //
        ComputeKernels[i] = clCreateKernel(ComputeProgram, KernelNames[i], &err);
        if (!ComputeKernels[i] || err != CL_SUCCESS)
        {
            printf("Error: Failed to create compute kernel!\n");
            return EXIT_FAILURE;
        }
		
        //		size_t wgSize = wgs;
        //		err = clGetKernelWorkGroupInfo(ComputeKernels[i], ComputeDeviceId, CL_KERNEL_WORK_GROUP_SIZE, sizeof(size_t), &wgSize, NULL);
        //		if(err)
        //		{
        //			printf("Error: Failed to get kernel work group size\n");
        //			return EXIT_FAILURE;
        //		}
		GROUP_SIZE = wgs;
		
    }
    
    free(source);
    
    return EXIT_SUCCESS;
}

@end
