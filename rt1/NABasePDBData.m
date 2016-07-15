//
//  NABasePDBData.m
//  rt1
//
//  Created by Callum Smits on 15/08/2014.
//  Copyright (c) 2014 a. All rights reserved.
//

#import "NABasePDBData.h"

NSString *dA = @"ATOM      1  P    DA A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1  DA A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2  DA A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'  DA A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'  DA A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'  DA A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'  DA A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'  DA A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'  DA A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'  DA A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'  DA A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  N9   DA A   1       0.723  -4.471   0.105  1.00 20.00           N\n\
ATOM     13  C8   DA A   1      -0.586  -4.834   0.296  1.00 20.00           C\n\
ATOM     14  N7   DA A   1      -1.411  -3.820   0.350  1.00 20.00           N\n\
ATOM     15  C5   DA A   1      -0.598  -2.705   0.189  1.00 20.00           C\n\
ATOM     16  C4   DA A   1       0.723  -3.087   0.040  1.00 20.00           C\n\
ATOM     17  N1   DA A   1       0.158  -0.464  -0.028  1.00 20.00           N\n\
ATOM     18  C2   DA A   1       1.390  -0.977  -0.155  1.00 20.00           C\n\
ATOM     19  N3   DA A   1       1.779  -2.265  -0.139  1.00 20.00           N\n\
ATOM     20  C6   DA A   1      -0.879  -1.315   0.145  1.00 20.00           C\n\
ATOM     21  N6   DA A   1      -2.111  -0.804   0.256  1.00 20.00           N\n\
";

NSString *dT = @"ATOM      1  P    DT A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1  DT A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2  DT A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'  DT A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'  DT A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'  DT A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'  DT A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'  DT A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'  DT A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'  DT A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'  DT A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  N1   DT A   1       0.652  -4.412   0.106  1.00 20.00           N\n\
ATOM     13  C2   DT A   1       0.838  -3.039   0.026  1.00 20.00           C\n\
ATOM     14  N3   DT A   1      -0.318  -2.305   0.133  1.00 20.00           N\n\
ATOM     15  C4   DT A   1      -1.596  -2.771   0.312  1.00 20.00           C\n\
ATOM     16  C5   DT A   1      -1.720  -4.212   0.407  1.00 20.00           C\n\
ATOM     17  C6   DT A   1      -0.600  -4.950   0.307  1.00 20.00           C\n\
ATOM     18  O2   DT A   1       1.938  -2.507  -0.131  1.00 20.00           O\n\
ATOM     19  O4   DT A   1      -2.530  -1.972   0.377  1.00 20.00           O\n\
ATOM     20  C7   DT A   1      -3.074  -4.811   0.604  1.00 20.00           C\n\
";

NSString *dC = @"ATOM      1  P    DC A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1  DC A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2  DC A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'  DC A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'  DC A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'  DC A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'  DC A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'  DC A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'  DC A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'  DC A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'  DC A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  N1   DC A   1       0.643  -4.426   0.116  1.00 20.00           N\n\
ATOM     13  C2   DC A   1       0.796  -3.044   0.026  1.00 20.00           C\n\
ATOM     14  N3   DC A   1      -0.304  -2.258   0.130  1.00 20.00           N\n\
ATOM     15  C4   DC A   1      -1.518  -2.795   0.308  1.00 20.00           C\n\
ATOM     16  C5   DC A   1      -1.700  -4.210   0.408  1.00 20.00           C\n\
ATOM     17  C6   DC A   1      -0.583  -4.979   0.299  1.00 20.00           C\n\
ATOM     18  O2   DC A   1       1.930  -2.577  -0.139  1.00 20.00           O\n\
ATOM     19  N4   DC A   1      -2.558  -1.981   0.398  1.00 20.00           N\n\
";

NSString *dG = @"ATOM      1  P    DG A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1  DG A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2  DG A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'  DG A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'  DG A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'  DG A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'  DG A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'  DG A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'  DG A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'  DG A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'  DG A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  N9   DG A   1       0.728  -4.472   0.106  1.00 20.00           N\n\
ATOM     13  C8   DG A   1      -0.586  -4.835   0.294  1.00 20.00           C\n\
ATOM     14  N7   DG A   1      -1.409  -3.819   0.350  1.00 20.00           N\n\
ATOM     15  C5   DG A   1      -0.599  -2.700   0.190  1.00 20.00           C\n\
ATOM     16  C4   DG A   1       0.718  -3.092   0.039  1.00 20.00           C\n\
ATOM     17  N1   DG A   1       0.231  -0.536  -0.024  1.00 20.00           N\n\
ATOM     18  C2   DG A   1       1.512  -1.022  -0.166  1.00 20.00           C\n\
ATOM     19  N3   DG A   1       1.813  -2.313  -0.141  1.00 20.00           N\n\
ATOM     20  C6   DG A   1      -0.909  -1.319   0.162  1.00 20.00           C\n\
ATOM     21  O6   DG A   1      -2.018  -0.779   0.278  1.00 20.00           O\n\
ATOM     22  N2   DG A   1       2.491  -0.117  -0.337  1.00 20.00           N\n\
";

NSString *rA = @"ATOM      1  P     A A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1   A A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2   A A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'   A A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'   A A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'   A A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'   A A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'   A A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'   A A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'   A A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'   A A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  O2'   A A   1       1.972  -6.391   2.132  1.00 30.00           O\n\
ATOM     13  N9    A A   1       0.718  -4.464   0.107  1.00 20.00           N\n\
ATOM     14  C8    A A   1      -0.584  -4.831   0.294  1.00 20.00           C\n\
ATOM     15  N7    A A   1      -1.411  -3.819   0.349  1.00 20.00           N\n\
ATOM     16  C5    A A   1      -0.598  -2.713   0.192  1.00 20.00           C\n\
ATOM     17  C4    A A   1       0.727  -3.091   0.037  1.00 20.00           C\n\
ATOM     18  N1    A A   1       0.155  -0.489  -0.004  1.00 20.00           N\n\
ATOM     19  C2    A A   1       1.386  -0.998  -0.142  1.00 20.00           C\n\
ATOM     20  N3    A A   1       1.777  -2.273  -0.137  1.00 20.00           N\n\
ATOM     21  C6    A A   1      -0.877  -1.342   0.166  1.00 20.00           C\n\
ATOM     22  N6    A A   1      -2.111  -0.846   0.303  1.00 20.00           N\n\
";

NSString *rU = @"ATOM      1  P     U A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1   U A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2   U A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'   U A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'   U A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'   U A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'   U A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'   U A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'   U A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'   U A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'   U A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  O2'   U A   1       1.972  -6.391   2.132  1.00 30.00           O\n\
ATOM     13  N1    U A   1       0.644  -4.411   0.114  1.00 20.00           N\n\
ATOM     14  C2    U A   1       0.826  -3.046   0.024  1.00 20.00           C\n\
ATOM     15  N3    U A   1      -0.326  -2.290   0.132  1.00 20.00           N\n\
ATOM     16  C4    U A   1      -1.604  -2.763   0.321  1.00 20.00           C\n\
ATOM     17  C5    U A   1      -1.696  -4.200   0.408  1.00 20.00           C\n\
ATOM     18  C6    U A   1      -0.596  -4.971   0.300  1.00 20.00           C\n\
ATOM     19  O2    U A   1       1.919  -2.536  -0.141  1.00 20.00           O\n\
ATOM     20  O4    U A   1      -2.561  -1.984   0.405  1.00 20.00           O\n\
";

NSString *rC = @"ATOM      1  P     C A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1   C A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2   C A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'   C A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'   C A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'   C A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'   C A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'   C A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'   C A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'   C A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'   C A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  O2'   C A   1       1.972  -6.391   2.132  1.00 30.00           O\n\
ATOM     13  N1    C A   1       0.641  -4.428   0.112  1.00 20.00           N\n\
ATOM     14  C2    C A   1       0.791  -3.040   0.031  1.00 20.00           C\n\
ATOM     15  N3    C A   1      -0.305  -2.255   0.128  1.00 20.00           N\n\
ATOM     16  C4    C A   1      -1.508  -2.806   0.305  1.00 20.00           C\n\
ATOM     17  C5    C A   1      -1.680  -4.216   0.405  1.00 20.00           C\n\
ATOM     18  C6    C A   1      -0.594  -4.978   0.304  1.00 20.00           C\n\
ATOM     19  O2    C A   1       1.932  -2.569  -0.128  1.00 20.00           O\n\
ATOM     20  N4    C A   1      -2.560  -1.991   0.384  1.00 20.00           N\n\
";

NSString *rG = @"ATOM      1  P     G A   1      -0.354  -9.215  -1.849  1.00 20.00           P\n\
ATOM      2  OP1   G A   1      -0.207 -10.499  -2.569  1.00 20.00           O\n\
ATOM      3  OP2   G A   1      -1.304  -9.104  -0.720  1.00 20.00           O\n\
ATOM      4  O5'   G A   1       1.084  -8.739  -1.333  1.00 20.00           O\n\
ATOM      5  O3'   G A   1       4.211  -6.835   0.518  1.00 20.00           O\n\
ATOM      6  C1'   G A   1       1.903  -5.330  -0.003  1.00 20.00           C\n\
ATOM      7  C2'   G A   1       1.811  -6.647   0.752  1.00 20.00           C\n\
ATOM      8  C3'   G A   1       2.971  -7.365   0.076  1.00 20.00           C\n\
ATOM      9  C4'   G A   1       2.757  -6.990  -1.386  1.00 20.00           C\n\
ATOM     10  C5'   G A   1       1.926  -7.975  -2.188  1.00 20.00           C\n\
ATOM     11  O4'   G A   1       2.086  -5.703  -1.354  1.00 20.00           O\n\
ATOM     12  O2'   G A   1       1.972  -6.391   2.132  1.00 30.00           O\n\
ATOM     13  N9    G A   1       0.730  -4.482   0.106  1.00 20.00           N\n\
ATOM     14  C8    G A   1      -0.586  -4.839   0.294  1.00 20.00           C\n\
ATOM     15  N7    G A   1      -1.410  -3.816   0.351  1.00 20.00           N\n\
ATOM     16  C5    G A   1      -0.600  -2.699   0.188  1.00 20.00           C\n\
ATOM     17  C4    G A   1       0.718  -3.083   0.040  1.00 20.00           C\n\
ATOM     18  N1    G A   1       0.193  -0.509  -0.004  1.00 20.00           N\n\
ATOM     19  C2    G A   1       1.473  -0.975  -0.150  1.00 20.00           C\n\
ATOM     20  N3    G A   1       1.795  -2.258  -0.136  1.00 20.00           N\n\
ATOM     21  C6    G A   1      -0.931  -1.317   0.179  1.00 20.00           C\n\
ATOM     22  O6    G A   1      -2.049  -0.793   0.307  1.00 20.00           O\n\
ATOM     23  N2    G A   1       2.427  -0.065  -0.319  1.00 20.00           N\n\
";

@implementation NABasePDBData

- (id)initWithBase:(NSString *)base naType:(uint)type {
    
    if (self = [super init]) {
        self.CPK = YES;
        if (type == kNucleicAcidTypeDNA) {
            if ([base isEqualToString:@"A"] || [base isEqualToString:@"a"]) {
                [self initWithPDBString:dA];
            } else if ([base isEqualToString:@"T"] || [base isEqualToString:@"t"]) {
                [self initWithPDBString:dT];
            } else if ([base isEqualToString:@"C"] || [base isEqualToString:@"c"]) {
                [self initWithPDBString:dC];
            } else if ([base isEqualToString:@"G"] || [base isEqualToString:@"g"]) {
                [self initWithPDBString:dG];
            } else {
                NSLog(@"Error: Trying to initialise Nucleic acid base PDB with invalid nucleitode");
            }
        } else if (type == kNucleicAcidTypeRNA) {
            if ([base isEqualToString:@"A"] || [base isEqualToString:@"a"]) {
                [self initWithPDBString:rA];
            } else if ([base isEqualToString:@"U"] || [base isEqualToString:@"u"]) {
                [self initWithPDBString:rU];
            } else if ([base isEqualToString:@"C"] || [base isEqualToString:@"c"]) {
                [self initWithPDBString:rC];
            } else if ([base isEqualToString:@"G"] || [base isEqualToString:@"g"]) {
                [self initWithPDBString:rG];
            } else {
                NSLog(@"Error: Trying to initialise Nucleic acid base PDB with invalid nucleitode");
            }
        }
    }
    
    return self;
}

@end
