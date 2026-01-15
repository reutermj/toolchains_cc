#include <gmp.h>
#include <stdio.h>

int main() {
    mpz_t a, b, result;

    // Initialize big integers
    mpz_init(a);
    mpz_init(b);
    mpz_init(result);

    // Set values - these are larger than 64-bit integers can hold
    mpz_set_str(a, "123456789012345678901234567890", 10);
    mpz_set_str(b, "987654321098765432109876543210", 10);

    // Addition
    mpz_add(result, a, b);
    printf("Addition:\n");
    gmp_printf("  %Zd\n+ %Zd\n= %Zd\n\n", a, b, result);

    // Multiplication
    mpz_mul(result, a, b);
    printf("Multiplication:\n");
    gmp_printf("  %Zd\n* %Zd\n= %Zd\n\n", a, b, result);

    // Factorial of 100
    mpz_fac_ui(result, 100);
    printf("100! = ");
    gmp_printf("%Zd\n\n", result);

    // Count digits in 100!
    size_t digits = mpz_sizeinbase(result, 10);
    printf("100! has %zu digits\n", digits);

    // Clean up
    mpz_clear(a);
    mpz_clear(b);
    mpz_clear(result);

    return 0;
}
