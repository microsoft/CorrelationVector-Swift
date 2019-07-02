// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AtomicHelper.h"

bool compareAndSwap(_Atomic(long) *value, long * expected, long desired) {
  return atomic_compare_exchange_strong(value, expected, desired);
}
