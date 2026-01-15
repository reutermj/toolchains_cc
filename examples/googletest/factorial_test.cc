#include "factorial.h"

#include <gtest/gtest.h>

TEST(FactorialTest, Zero) {
    EXPECT_EQ(factorial(0), 1);
}

TEST(FactorialTest, One) {
    EXPECT_EQ(factorial(1), 1);
}

TEST(FactorialTest, Positive) {
    EXPECT_EQ(factorial(2), 2);
    EXPECT_EQ(factorial(3), 6);
    EXPECT_EQ(factorial(5), 120);
    EXPECT_EQ(factorial(10), 3628800);
}

TEST(FactorialTest, Negative) {
    EXPECT_EQ(factorial(-1), 1);
    EXPECT_EQ(factorial(-5), 1);
}
