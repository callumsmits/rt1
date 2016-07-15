//
//  prefixSumScan.h
//  rt1
//
//  Created by Callum Smits on 16/07/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenCL/OpenCL.h>

@interface prefixSumScan : NSObject

- (bool)initPreScan:(cl_device_id)device queue:(cl_command_queue)queue context:(cl_context)context wgs:(int)wgs;
- (void)PreScanBuffer:(cl_mem)output_data inputData:(cl_mem)input_data maxGroupSize:(unsigned int)max_group_size maxWorkItemCount:(unsigned int)max_work_item_count elementCount:(unsigned int)element_count;


@end
