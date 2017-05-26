#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>

#define STR_LEN 100
#define FATAL_MSG( ... ) \
do { \
    fprintf(stderr,"[%s:%d] Fatal error: ",__FILE__,__LINE__); \
    fprintf(stderr, __VA_ARGS__); \
    } while(0)
#define WARN_MSG( ... ) \
do { \
    fprintf(stderr,"[%s:%d] Warning: ",__FILE__,__LINE__); \
    fprintf(stderr, __VA_ARGS__); \
    } while(0)

typedef struct
{
    unsigned char UB;
    unsigned char LB;
} instruction_t;
typedef struct
{
    unsigned short int byte2;
} instruction_2;

int getNextLine( FILE* file, char* dest, int n);
int insertHex ( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum);
int insertADD ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertADDi( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertAND ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertANDi( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertNOT ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertBR  ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertJMP ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertJSR ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertLDR ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertSTR ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertLD  ( FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);

/* parallel instructions */
int insertPC_INIT(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertCPU_SEL(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertSYNC(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertREADY(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertBR_CPUID(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertWAIT(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);
int insertINTR_PC(FILE* binFile, char* string, FILE* test_memfile,unsigned long instructionNum);

int main(int argc, char* argv[] )
{
    if ( argc != 2 )
    {
        printf("******************\n");
        printf("* PLC3 assembler *\n");
        printf("******************\n\n");
        printf("Usage: ./PLC3asm [.asm file]\n");
        return 0;
    }

    char* curLine;
    int status;
    int GNLstatus;
    int retStat = 0;
    unsigned long instructionNum = 0;
    // Open assembly text file
    FILE* inFile = fopen(argv[1], "r");
    if ( inFile == NULL )
    {
        FATAL_MSG("Unable to open file.");
        goto cleanupFail;
    }

    // Create binary file
    FILE* binFile = fopen("binFile.bin", "wb");
    curLine = malloc(STR_LEN);

    // Create the test_mem file
    FILE* test_memfile = fopen("test_mem.txt", "w");

    do
    {
        memset(curLine, 0, STR_LEN);
        GNLstatus = getNextLine(inFile, curLine, STR_LEN);
        if ( GNLstatus == 1)
        {
            FATAL_MSG("Failed to get next line. Exiting program.\n");
            goto cleanupFail;
        }
        else if ( GNLstatus == -1 ) break;

        /* CURRENT LINE IS A HEX NUMBER */
        if (curLine[0] == '0' && (curLine[1] == 'x' || curLine[1] == 'X'))
        {
            status = insertHex(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("insertHex failed.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }

        /* CURRENT LINE IS ADD */
        else if ( strstr(curLine, "ADD ") != NULL )
        {
            status = insertADD(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert ADD instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }

        /* CURRENT LINE IS ADDi */
        else if ( strstr(curLine, "ADDi ") != NULL )
        {
            status = insertADDi(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert ADDi instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }

        }
        /* CURRENT LINE IS AND */
        else if ( strstr(curLine, "AND ") != NULL )
        {
            status = insertAND(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert AND instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }

        }
        else if ( strstr(curLine, "ANDi ") != NULL )
        {
            status = insertANDi(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert ANDi instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }

        }

        else if ( strstr(curLine, "NOT ") != NULL)
        {
            status = insertNOT(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert NOT instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }

        /* This conflicts with the BR_CPUID during the strstr check. Consider
         * moving this to after the BR_CPUID check
         */
        else if ( strstr(curLine, "BR") != NULL && strstr(curLine, "BR_CPUID") == NULL)
        {
            status = insertBR(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert BR instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "JMP ") != NULL)
        {
            status = insertJMP(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert JMP instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }

        else if ( strstr(curLine, "JSR ") != NULL)
        {
            status = insertJSR(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert JSR instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "LDR ") != NULL)
        {
            status = insertLDR(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert LDR instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "STR ") != NULL)
        {
            status = insertSTR(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert STR instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "PC_INIT ") != NULL)
        {
            status = insertPC_INIT(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert PC_INIT instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "CPU_SEL ") != NULL)
        {
            status = insertCPU_SEL(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert CPU_SEL instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "SYNC ") != NULL)
        {
            status = insertSYNC(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert SYNC instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "READY") != NULL)
        {
            status = insertREADY(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert READY instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "BR_CPUID ") != NULL)
        {
            status = insertBR_CPUID(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert BR_CPUID instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "WAIT") != NULL)
        {
            status = insertWAIT(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert WAIT instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "INTR_PC") != NULL)
        {
            status = insertINTR_PC(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert INTR_PC instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else if ( strstr(curLine, "LD ") != NULL)
        {
            status = insertLD(binFile, curLine, test_memfile, instructionNum);
            if ( status != 0 )
            {
                FATAL_MSG("Failed to insert LD instruction.\ncurLine = \"%s\"\n", curLine);
                goto cleanupFail;
            }
        }
        else
        {
            FATAL_MSG("Failed to interpret the current line.\n\tcurLine = %s\n",curLine);
            goto cleanupFail;
        }

        instructionNum++;
    }
    while ( GNLstatus == 0 );

    if ( 0 )
    {
cleanupFail:
        retStat = 1;
    }

    fclose(inFile);
    fclose(binFile);
    free(curLine);

    return retStat;

}

int getNextLine( FILE* file, char* dest, int n)
{
    int i;
    char* tempStr = malloc ( n );
    do
    {
        memset(tempStr, 0, n);
        if ( fgets(tempStr, n, file) == NULL)
        {
            if ( feof(file) != 0 )
                return -1;
            FATAL_MSG("Unable to get next line.\n");
            return 1;
        }

        /* Find the first alphabetic character */
        for ( i = 0; i < n-1; i++)
        {
            if ((tempStr[i] >= 'a' && tempStr[i] <= 'z') ||
                    (tempStr[i] >= 'A' && tempStr[i] <= 'Z') ||
                    (tempStr[i] == '0' && (tempStr[i+1] == 'x' || tempStr[i+1] == 'X')) ||
                    tempStr[i] == '#')
            {
                break;
            }

        }
    }
    while( i == n-1 || tempStr[i] == '#');

    int j;
    for ( j = 0; j < n-1; j++)
    {
        if (tempStr[j+i] == '\0' || tempStr[j+i] == '\n' ) break;
        dest[j] = tempStr[j+i];
    }
    free(tempStr);
    return 0;
}

uint16_t get_bit(unsigned short int bits, uint8_t pos)
{
    return (bits >> pos) & 0x0001;
}

int get_test_mem_line (char* destString, unsigned long instructionNum, unsigned short instr )
{
    if ( destString == NULL )
    {
        FATAL_MSG("A NULL pointer was passed to this function.\n");
        return -1;
    }
    memset(destString,0,STR_LEN);
    sprintf(destString, "mem_array[%lu] <= 16'b", instructionNum);

    int i = 0;
    while (destString[i] != '\0')
        i++;

    int j;

    for ( j = 0; j < 16; j++)
    {
        if (i+j >= STR_LEN)
        {
            FATAL_MSG("STR_LEN is not large enough to store the string.\n");
            return -1;
        }
        destString[i+j] = get_bit(instr, 15-j) + 48;
    }

    if (i+j >= STR_LEN)
    {
        FATAL_MSG("STR_LEN is not large enough to store the string.\n");
        return -1;
    }

    destString[i+j] = ';';
    j++;
    if (i+j >= STR_LEN)
    {
        FATAL_MSG("STR_LEN is not large enough to store the string.\n");
        return -1;
    }
    destString[i+j] = '\n';

    return 0;
}

int insertHex( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    // convert ASCII hex to ulong
    char* tail = NULL;
    instruction_t hexNumber;

    unsigned long convertedVal = strtoul(string, &tail, 16);

    // Convert the unsigned long into a 2-byte type.
    unsigned short twoByte = (unsigned short) convertedVal;

    hexNumber.UB = (unsigned char) (twoByte >> 8);
    hexNumber.LB = (unsigned char) (twoByte & 0x00ff);

    // Write this to the binary file

    size_t numWritten = fwrite(&hexNumber, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }

    instruction_2 instr;
    instr.byte2 = (hexNumber.UB << 8) | hexNumber.LB;

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    return 0;
}

int insertADD( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "ADD");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not ADD!\n");
        return -1;
    }
    char* DR = strstr(string, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for ADD instruction.\n");
        return -1;
    }

    char* SR1 = strstr(DR+1, "R");
    if ( SR1 == NULL )
    {
        FATAL_MSG("Failed to find the 1st source register for ADD instruction.\n");
        return -1;
    }

    char* SR2 = strstr(SR1+1, "R");
    if ( SR2 == NULL )
    {
        FATAL_MSG("Failed to find the 2nd source register for ADD instruction.\n");
        return -1;
    }

    instruction_2 instr;
    instr.byte2 = 0;

    unsigned char DRcode, SR1code, SR2code;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the destination register number.\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(SR1+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the SR1 register number.\n");
        return -1;
    }

    SR1code = tempInt;

    tempInt = (int)(*(SR2+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the SR2 register number.\n");
        return -1;
    }

    SR2code = tempInt;

    instr.byte2 = (0x1 << 12) | ((DRcode & 0x7) << 9) | ((SR1code & 0x7) << 7) | ((SR2code & 0x7));

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }






    return 0;

}

int insertADDi ( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "ADDi ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not ADDi!\n");
        return -1;
    }
    char* DR = strstr(string, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for ADD instruction.\n");
        return -1;
    }

    char* SR1 = strstr(DR+1, "R");
    if ( SR1 == NULL )
    {
        FATAL_MSG("Failed to find the 1st source register for ADD instruction.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm5 = SR1+2;

    while ( !isdigit(*imm5) )
    {
        imm5++;
    }

    if (*(imm5-1) == '-')
        imm5--;

    /* find the tail of the immediate value */
    char* imm5Tail = imm5;
    while ( isdigit(*(imm5Tail+1)) )
    {
        imm5Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);
    int i;
    for (i = 0; i < STR_LEN && imm5 <= imm5Tail; i++)
    {
        numberStr[i] = *imm5;
        imm5++;
    }

    int immediateNum = atoi(numberStr);

    if ( immediateNum < -16 || immediateNum > 15 )
    {
        FATAL_MSG("Provided immediate value exceeds supported range. Can only be in the range [-16,15] inclusive!\n\tcurLine = %s test\n", string);
        return -1;
    }

    instruction_2 instr;

    unsigned char DRcode, SR1code;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the destination register number.\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(SR1+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the SR1 register number.\n");
        return -1;
    }

    SR1code = tempInt;

    instr.byte2 = 0;

    instr.byte2 = (0x1 << 12) | (DRcode << 9) | (SR1code << 6) | (0x1 << 5) |
                      (immediateNum & 0x1F);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }






    return 0;
}


int insertAND( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "AND ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not AND!\n");
        return -1;
    }

    char* DR = strstr(string, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for AND instruction.\n");
        return -1;
    }

    char* SR1 = strstr(DR+1, "R");
    if ( SR1 == NULL )
    {
        FATAL_MSG("Failed to find the 1st source register for AND instruction.\n");
        return -1;
    }

    char* SR2 = strstr(SR1+1, "R");
    if ( SR2 == NULL )
    {
        FATAL_MSG("Failed to find the 2nd source register for AND instruction.\n");
        return -1;
    }

    instruction_t instr;
    instr.UB = 0;
    instr.LB = 0;

    unsigned char DRcode, SR1code, SR2code;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the destination register number.\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(SR1+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the SR1 register number.\n");
        return -1;
    }

    SR1code = tempInt;

    tempInt = (int)(*(SR2+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Failed to find the SR2 register number.\n");
        return -1;
    }

    SR2code = tempInt;
    // the lower 4 bits of the instr.UB
    unsigned char lower4 = (DRcode << 1) | ((SR1code & 0x4) >> 2);
    instr.UB = (0x5 << 4) | (lower4);

    // upper 4 bits of instr.LB
    unsigned char upper4 = (SR1code & 0x3) << 6;
    instr.LB = upper4 | (SR2code & 0x7);
    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }


    instruction_2 instr2;
    instr2.byte2 = (instr.LB << 8) | instr.UB;

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr2.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }


    return 0;

}

int insertANDi ( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "ANDi ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not ANDi!.\n");
        return -1;
    }
    char* DR = strstr(string, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for ANDi instruction.\n");
        return -1;
    }

    char* SR1 = strstr(DR+1, "R");
    if ( SR1 == NULL )
    {
        FATAL_MSG("Failed to find the 1st source register for ANDi instruction.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm5 = SR1+2;

    while ( !isdigit(*imm5) )
    {
        imm5++;
    }

    if (*(imm5-1) == '-')
        imm5--;

    /* find the tail of the immediate value */
    char* imm5Tail = imm5;
    while ( isdigit(*(imm5Tail+1)) )
    {
        imm5Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);
    int i;
    for (i = 0; i < STR_LEN && imm5 <= imm5Tail; i++)
    {
        numberStr[i] = *imm5;
        imm5++;
    }

    int immediateNum = atoi(numberStr);

    if ( immediateNum < -16 || immediateNum > 15 )
    {
        FATAL_MSG("Provided immediate value exceeds supported range. Can only be in the range [-16,15] inclusive!\n\tcurLine = %s test\n", string);
        return -1;
    }

    instruction_2 instr;

    unsigned char DRcode, SR1code;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(SR1+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    SR1code = tempInt;

    instr.byte2 = 0;

    instr.byte2 = (0x5 << 12) | (DRcode << 9) | (SR1code << 6) | (0x1 << 5 ) |
                      (immediateNum & 0x1F);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }




    return 0;
}

int insertNOT( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "NOT " );
    if ( op == NULL )
    {
        FATAL_MSG("Received instruction isn't a NOT operation.\n");
        return -1;
    }

    char* DR = strstr(op+3, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register.\n");
        return -1;
    }

    char* SR = strstr(DR+1, "R");
    if ( SR == NULL )
    {
        FATAL_MSG("Failed to find the source register.\n");
        return -1;
    }

    unsigned char DRcode, SRcode;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(SR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    SRcode = tempInt;

    instruction_2 instr;
    instr.byte2 = 0;

    instr.byte2 = (0x9 << 12) | (DRcode << 9) | (SRcode << 6) | 0x3f;

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }




    return 0;
}

int insertBR(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "BR" );
    if ( op == NULL )
    {
        FATAL_MSG("Received instruction isn't a BR operation.\n");
        return -1;
    }

    unsigned short int n,z,p;
    n = 0;
    z = 0;
    p = 0;

    if ( strstr(string, "n") != NULL)
        n = 1;
    if ( strstr(string, "z") != NULL)
        z = 1;
    if (strstr(string, "p") != NULL)
        p = 1;

    if ( !n && !p && !z)
    {
        WARN_MSG("Branch instruction provided no nzp conditions!\n\tThis will result in a branch that will never execute.\n");
    }

    /* Find the immediate value */
    char* imm9 = op;

    while ( !isdigit(*imm9) )
    {
        imm9++;
        if ( *imm9 == '\0')
        {
            FATAL_MSG("An immediate value was not provided for the branch instruction.\n");
            return -1;
        }
    }

    if (*(imm9-1) == '-')
        imm9--;

    /* find the tail of the immediate value */
    char* imm9Tail = imm9;
    while ( isdigit(*(imm9Tail+1)) )
    {
        imm9Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);
    int i;
    for (i = 0; i < STR_LEN && imm9 <= imm9Tail; i++)
    {
        numberStr[i] = *imm9;
        imm9++;
    }

    int immediateNum = atoi(numberStr);

    if ( immediateNum < -256 || immediateNum > 255 )
    {
        FATAL_MSG("Provided immediate value exceeds supported range. Can only be in the range [-256,255] inclusive!\n\tcurLine = %s test\n", string);
        return -1;
    }

    instruction_2 instr;
    instr.byte2 = 0;

    instr.byte2 = ((n & 0x1) << 11) | ((z & 0x1) << 10) | ((p & 0x1) << 9) | (immediateNum & 0x1FF);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }



    return 0;
}

int insertJMP(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "JMP " );
    if ( op == NULL )
    {
        FATAL_MSG("Received instruction isn't a JMP operation.\n");
        return -1;
    }

    char* BR = strstr(op+3, "R");
    if ( BR == NULL )
    {
        FATAL_MSG("Failed to find the base register.\n");
        return -1;
    }

    unsigned char BRcode;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(BR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    BRcode = tempInt;

    instruction_2 instr;
    instr.byte2 = 0;

    instr.byte2 = (0xc << 12) | (BRcode << 6);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }
    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }



    return 0;
}

int insertJSR(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "JSR " );
    if ( op == NULL )
    {
        FATAL_MSG("Received instruction isn't a JSR operation.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm11 = op;

    while ( !isdigit(*imm11) )
    {
        imm11++;
    }

    if (*(imm11-1) == '-')
        imm11--;

    /* find the tail of the immediate value */
    char* imm11Tail = imm11;
    while ( isdigit(*(imm11Tail+1)) )
    {
        imm11Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);
    int i;
    for (i = 0; i < STR_LEN && imm11 <= imm11Tail; i++)
    {
        numberStr[i] = *imm11;
        imm11++;
    }

    int immediateNum = atoi(numberStr);

    if ( immediateNum < -1024 || immediateNum > 1023 )
    {
        FATAL_MSG("Provided immediate value exceeds supported range. Can only be in the range [-1024,1023] inclusive!\n");
        return -1;
    }

    instruction_2 instr;
    instr.byte2 = 0;

    instr.byte2 = (0x4 << 12) | (0x1 << 11) | (immediateNum & 0x7ff);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }
    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >> 8) | (instr.byte2 << 8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }



    return 0;
}

int insertLDR ( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "LDR ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not LDR!\n");
        return -1;
    }
    char* DR = strstr(op+3, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for JSR instruction.\n");
        return -1;
    }

    char* BR = strstr(DR+1, "R");
    if ( BR == NULL )
    {
        FATAL_MSG("Failed to find the base register for JSR instruction.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm6 = BR+2;

    while ( !isdigit(*imm6) )
    {
        imm6++;
    }

    if (*(imm6-1) == '-')
        imm6--;

    /* find the tail of the immediate value */
    char* imm6Tail = imm6;
    while ( isdigit(*(imm6Tail+1)) )
    {
        imm6Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);
    int i;
    for (i = 0; i < STR_LEN && imm6 <= imm6Tail; i++)
    {
        numberStr[i] = *imm6;
        imm6++;
    }

    int immediateNum = atoi(numberStr);

    if ( immediateNum < -32 || immediateNum > 31 )
    {
        FATAL_MSG("Provided immediate value exceeds supported range. Can only be in the range [-32,31] inclusive!\n");
        return -1;
    }

    instruction_2 instr;

    unsigned char DRcode, BRcode;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(BR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    BRcode = tempInt;

    instr.byte2 = 0;

    instr.byte2 = (0x6 << 12) | (DRcode << 9) | (BRcode << 6) | (immediateNum & 0x3f);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }




    return 0;
}

int insertSTR ( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "STR ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not STR!\n");
        return -1;
    }
    char* DR = strstr(op+3, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for STR instruction.\n");
        return -1;
    }

    char* BR = strstr(DR+1, "R");
    if ( BR == NULL )
    {
        FATAL_MSG("Failed to find the base register for STR instruction.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm6 = BR+2;

    while ( !isdigit(*imm6) )
    {
        imm6++;
    }

    if (*(imm6-1) == '-')
        imm6--;

    /* find the tail of the immediate value */
    char* imm6Tail = imm6;
    while ( isdigit(*(imm6Tail+1)) )
    {
        imm6Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);
    int i;
    for (i = 0; i < STR_LEN && imm6 <= imm6Tail; i++)
    {
        numberStr[i] = *imm6;
        imm6++;
    }

    int immediateNum = atoi(numberStr);

    if ( immediateNum < -32 || immediateNum > 31 )
    {
        FATAL_MSG("Provided immediate value exceeds supported range. Can only be in the range [-32,31] inclusive!\n");
        return -1;
    }

    instruction_2 instr;

    unsigned char DRcode, BRcode;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    DRcode = tempInt;

    tempInt = (int)(*(BR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    BRcode = tempInt;

    instr.byte2 = 0;

    instr.byte2 = (0x7 << 12) | (DRcode << 9) | (BRcode << 6) | immediateNum;

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }




    return 0;
}


int insertPC_INIT(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    int i;
    char* op = strstr(string, "PC_INIT ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not PC_INIT!\n");
        return -1;
    }
    char* SR = strstr(op, "R");
    if ( SR == NULL )
    {
        FATAL_MSG("Failed to find the source register for PC_INIT instruction.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm4 = SR+2;

    while ( !isdigit(*imm4) )
    {
        imm4++;
    }

    /* find the tail of the immediate value */
    char* imm4Tail = imm4;
    while ( isdigit(*(imm4Tail+1)) )
    {
        imm4Tail++;
    }

    if ( imm4Tail - imm4 != 3)
    {
        FATAL_MSG("The provided immediate value must be a 4-bit binary number!\n");
        return -1;
    }

    int PC_X[4];
    for ( i = 0; i < 4; i++)
    {
        if ( *(imm4+i) == '0' )
        {
            PC_X[i] = 0;
        }
        else if ( *(imm4+i) == '1')
        {
            PC_X[i] = 1;
        }
        else
        {
            FATAL_MSG("The provided immediate value must be a 4-bit binary number!\n");
            return -1;
        }
    }

    instruction_2 instr;

    unsigned char SRcode;
    int tempInt;

    /* Convert the SR number from ASCII to an int */
    tempInt = (int)(*(SR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    SRcode = tempInt;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (SRcode << 6) | (PC_X[0] << 3) | (PC_X[1] << 2) |
                  (PC_X[2] << 1) | PC_X[3];

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }




    return 0;
}


int insertCPU_SEL(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    int i;
    char* op = strstr(string, "CPU_SEL ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not CPU_SEL!\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm4 = op+7;

    while ( !isdigit(*imm4) )
    {
        imm4++;
    }

    /* find the tail of the immediate value */
    char* imm4Tail = imm4;
    while ( isdigit(*(imm4Tail+1)) )
    {
        imm4Tail++;
    }

    if ( imm4Tail - imm4 != 3)
    {
        FATAL_MSG("The provided immediate value must be a 4-bit binary number!\n");
        return -1;
    }

    int CPU_SEL[4];
    for ( i = 0; i < 4; i++)
    {
        if ( *(imm4+i) == '0' )
        {
            CPU_SEL[i] = 0;
        }
        else if ( *(imm4+i) == '1')
        {
            CPU_SEL[i] = 1;
        }
        else
        {
            FATAL_MSG("The provided immediate value must be a 4-bit binary number!\n");
            return -1;
        }
    }

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (0x1 << 9) | (CPU_SEL[0] << 3) | (CPU_SEL[1] << 2) |
                  (CPU_SEL[2] << 1) | CPU_SEL[3];

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }



    return 0;
}
int insertSYNC(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    int i;
    char* op = strstr(string, "SYNC ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not SYNC!\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm4 = op+4;

    while ( !isdigit(*imm4) )
    {
        imm4++;
    }

    /* find the tail of the immediate value */
    char* imm4Tail = imm4;
    while ( isdigit(*(imm4Tail+1)) )
    {
        imm4Tail++;
    }

    if ( imm4Tail - imm4 != 3)
    {
        FATAL_MSG("The provided immediate value must be a 4-bit binary number!\n");
        return -1;
    }

    int CPU_X[4];
    for ( i = 0; i < 4; i++)
    {
        if ( *(imm4+i) == '0' )
        {
            CPU_X[i] = 0;
        }
        else if ( *(imm4+i) == '1')
        {
            CPU_X[i] = 1;
        }
        else
        {
            FATAL_MSG("The provided immediate value must be a 4-bit binary number!\n");
            return -1;
        }
    }

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (0x2 << 9) | (CPU_X[0] << 3) | (CPU_X[1] << 2) |
                  (CPU_X[2] << 1) | CPU_X[3];

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }




    return 0;
}
int insertREADY(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "READY");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not READY!\n");
        return -1;
    }

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (0x3 << 9);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }


    return 0;
}
int insertBR_CPUID(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    int i;
    char* op = strstr(string, "BR_CPUID ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not BR_CPUID!\n");
        return -1;
    }

    /* Find the fisrt immediate value */
    char* imm3 = op+8;

    while ( !isdigit(*imm3) )
    {
        imm3++;
    }

    /* find the tail of the immediate value */
    char* imm3Tail = imm3;
    while ( isdigit(*(imm3Tail+1)) )
    {
        imm3Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */
    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);

    for (i = 0; i < STR_LEN && imm3 <= imm3Tail; i++)
    {
        numberStr[i] = *imm3;
        imm3++;
    }

    int CPUID = atoi(numberStr);

    if ( CPUID < 0 && CPUID > 7 )
    {
        FATAL_MSG("The first immediate value provided exceeds supported range. Can only be in the range [0,7] inclusive!\n");
        return -1;
    }

    /* Find the second immediate value */
    char* imm9 = imm3Tail+1;

    while ( !isdigit(*imm9) )
    {
        imm9++;
    }

    if (*(imm9-1) == '-')
        imm9--;


    /* find the tail of the immediate value */
    char* imm9Tail = imm9;
    while ( isdigit(*(imm9Tail+1)) )
    {
        imm9Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */

    memset(numberStr, 0, STR_LEN);

    for (i = 0; i < STR_LEN && imm9 <= imm9Tail; i++)
    {
        numberStr[i] = *imm9;
        imm9++;
    }

    int PCoffset = atoi(numberStr);

    if ( PCoffset < -32 || PCoffset > 31 )
    {
        FATAL_MSG("Second immediate value exceeds supported range. Can only be in the range [-32,31] inclusive!\n\tcurLine = %s test\n", string);
        return -1;
    }

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (0x6 << 9) |
                  ((CPUID & 0x7) << 6) | (PCoffset & 0x3f);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }



    return 0;

}
int insertWAIT(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "WAIT");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not WAIT!\n");
        return -1;
    }

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (0x4 << 9);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }


    return 0;
}
int insertINTR_PC(FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    char* op = strstr(string, "INTR_PC");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not INTR_PC!\n");
        return -1;
    }

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0xd << 12) | (0x5 << 9);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }


    return 0;
}

insertLD( FILE* binFile, char* string, FILE* test_memfile, unsigned long instructionNum)
{
    int i;
    char* op = strstr(string, "LD ");
    if ( op == NULL )
    {
        FATAL_MSG("Received operation is not LD!\n");
        return -1;
    }

    char* DR = strstr(op+2, "R");
    if ( DR == NULL )
    {
        FATAL_MSG("Failed to find the destination register for STR instruction.\n");
        return -1;
    }

    /* Find the immediate value */
    char* imm9 = DR+2;

    while ( !isdigit(*imm9) )
    {
        imm9++;
    }

    if (*(imm9-1) == '-')
        imm9--;


    /* find the tail of the immediate value */
    char* imm9Tail = imm9;
    while ( isdigit(*(imm9Tail+1)) )
    {
        imm9Tail++;
    }

    /* copy this number over to new string (so that string contains only integer) */

    char numberStr[STR_LEN];
    memset(numberStr, 0, STR_LEN);

    for (i = 0; i < STR_LEN && imm9 <= imm9Tail; i++)
    {
        numberStr[i] = *imm9;
        imm9++;
    }

    int PCoffset = atoi(numberStr);


    if ( PCoffset < -256 || PCoffset > 255 )
    {
        FATAL_MSG("Immediate value exceeds supported range. Can only be in the range [-256,255] inclusive!\n\tcurLine = %s test\n", string);
        return -1;
    }

    unsigned char DRcode;
    int tempInt;

    /* Convert the DR number from ASCII to an int */
    tempInt = (int)(*(DR+1) - 48);

    if ( tempInt < 0 || tempInt > 7 )
    {
        FATAL_MSG("Register can only be numbered 0 through 7!\n");
        return -1;
    }

    DRcode = tempInt;

    instruction_2 instr;

    instr.byte2 = 0;

    instr.byte2 = (0x2 << 12) | (DRcode << 9) | ( PCoffset & 0x1ff);

    char test_memLine[STR_LEN];
    int status = get_test_mem_line(test_memLine, instructionNum, instr.byte2);
    if ( status != 0)
    {
        FATAL_MSG("Failed to generate test_mem line.\n");
        return -1;
    }

    status = fprintf(test_memfile, test_memLine);
    if ( status < 0 )
    {
        FATAL_MSG("Failed to print to file.\n");
        return -1;
    }

    /* We need to swap the endianness of instr.byte. It's backwards! */
    instr.byte2 = (instr.byte2 >>8) | (instr.byte2 <<8);

    size_t numWritten = fwrite(&instr, 2, 1, binFile);
    if ( numWritten != 1 )
    {
        FATAL_MSG("Failed to write to file.\n");
        return -1;
    }

    return 0;
}
