// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <stdatomic.h>
#import <stdbool.h>

bool compareAndSwap(_Atomic(long) *value, long * expected, long desired);
