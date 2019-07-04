// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "AtomicHelper.h"

bool compareAndSwap(_Atomic(uint32_t) *value, uint32_t *expected, uint32_t desired) {
  return atomic_compare_exchange_strong(value, expected, desired);
}
