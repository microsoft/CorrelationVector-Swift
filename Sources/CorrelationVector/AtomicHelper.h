// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <stdatomic.h>
#import <stdbool.h>

/**
 Compare and exchange contained value.
 Automatic binding to swift doesn't work due to the bug - https://openradar.appspot.com/27161329
 */
bool compareAndSwap(_Atomic(long) *value, long * expected, long desired);
