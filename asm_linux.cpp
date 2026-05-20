#include <ctype.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INSTSIZE 32

const char* mnemonics[] = {"j",    "jz",   "jnz", "call", "ret",  "ei",
                           "di",   "reti", "nop", "li",   "mov",  "not",
                           "add",  "sub",  "and", "or",   "neg",  "addi",
                           "subi", "andi", "ori", "load", "store"};

const char* opcodes[] = {"000000", "000001", "000010", "000011", "000100",
                         "000101", "000110", "000111", "001111", "010000",
                         "100000", "100010", "100100", "100110", "101000",
                         "101010", "101100", "100101", "100111", "101001",
                         "101011", "110001", "110010"};

#define MAXNUMOPER 3

const char* operands[] = {"D",  "D",   "D",   "D",   "",    "",    "",    "",
                          "",   "CR",  "RR",  "RR",  "RRR", "RRR", "RRR", "RRR",
                          "RR", "RCR", "RCR", "RCR", "RCR", "RRD", "RRD"};

#define CONSTANTSIZE 16
#define REGFIELDSIZE 4
#define DESTDIRSIZE 10

#define NUMINS (sizeof(mnemonics) / sizeof(mnemonics[0]))

const int posoper[NUMINS][MAXNUMOPER] = {
    {9, 0, 0},     // j     D
    {9, 0, 0},     // jz    D
    {9, 0, 0},     // jnz   D
    {9, 0, 0},     // call  D
    {0, 0, 0},     // ret
    {0, 0, 0},     // ei
    {0, 0, 0},     // di
    {0, 0, 0},     // reti
    {0, 0, 0},     // nop
    {17, 25, 0},   // li    CR        -> INM en [17:2], RD en [25:22]
    {21, 25, 0},   // mov   RR
    {21, 25, 0},   // not   RR
    {21, 17, 25},  // add   RRR
    {21, 17, 25},  // sub   RRR
    {21, 17, 25},  // and   RRR
    {21, 17, 25},  // or    RRR
    {21, 25, 0},   // neg   RR
    {21, 17, 25},  // addi  RCR
    {21, 17, 25},  // subi  RCR
    {21, 17, 25},  // andi  RCR
    {21, 17, 25},  // ori   RCR
    {25, 21,
     11},  // load  RRD       -> RD en [25:22], RB en [21:18], DESP en [11:2]
    {25, 21,
     11}};  // store RRD       -> RF en [25:22], RB en [21:18], DESP en [11:2]

// === resto del código IDÉNTICO al asm_linux.cpp original ===

#define MAXLINE 256
constexpr auto MAXPROGRAMLEN = (1 << DESTDIRSIZE);
char progmem[MAXPROGRAMLEN][INSTSIZE + 1];
char instrucc[INSTSIZE + 1];
int counter = 0;
constexpr auto MAXSYMBOLLEN = 50;
#define MAXSYMBREFS 1000
struct SymbRef {
  char Symbol[MAXSYMBOLLEN + 1];
  int LineRef;
  int PosRef;
  int BitPos;
  int Size;
};
struct SymbRef tablaR[MAXSYMBREFS];
int numRefs = 0;
#define MAXSYMBOLS 1000
struct SymbEnt {
  char Symbol[MAXSYMBOLLEN + 1];
  int Value;
  int LineDef;
};
struct SymbEnt tablaS[MAXSYMBOLS];
int numSymb = 0;

int operNumBits(int idopcode, int idxOper) {
  char codeOperand = operands[idopcode][idxOper];
  switch (codeOperand) {
    case 'C':
      return CONSTANTSIZE;
    case 'R':
      return REGFIELDSIZE;
    case 'D':
      return DESTDIRSIZE;
    default:
      return -1;
  }
}

void convBin(unsigned int number, char* destStr, size_t numchars) {
  unsigned int numero = number;
  for (int i = 0; i < (int)numchars; i++) {
    *(destStr + numchars - 1 - i) = (numero % 2) ? '1' : '0';
    numero >>= 1;
  }
}

int findStr(const char* str, const char** liststr, int nelem) {
  for (int i = 0; i < nelem; i++)
    if (strcmp(liststr[i], str) == 0) return i;
  return -1;
}

void addSymbRef(const char* sym, int line, int pos, int bitpos, int numbits) {
  if (numRefs < MAXSYMBREFS) {
    strncpy(tablaR[numRefs].Symbol, sym, MAXSYMBOLLEN + 1);
    tablaR[numRefs].Symbol[MAXSYMBOLLEN] = '\0';
    tablaR[numRefs].LineRef = line;
    tablaR[numRefs].PosRef = pos;
    tablaR[numRefs].BitPos = bitpos;
    tablaR[numRefs].Size = numbits;
    numRefs++;
  }
}

void addSymbol(const char* sym, int value, int srcline) {
  if (numSymb < MAXSYMBOLS) {
    strncpy(tablaS[numSymb].Symbol, sym, MAXSYMBOLLEN + 1);
    tablaS[numSymb].Symbol[MAXSYMBOLLEN] = '\0';
    tablaS[numSymb].Value = value;
    tablaS[numSymb].LineDef = srcline;
    numSymb++;
  }
}

int getSymbolIdx(int lineadef) {
  for (int i = 0; i < numSymb; i++)
    if (tablaS[i].LineDef == lineadef) return i;
  return -1;
}

int getSymbolValue(const char* sym) {
  for (int i = 0; i < numSymb; i++)
    if (!strncmp(tablaS[i].Symbol, sym, strlen(sym))) return tablaS[i].Value;
  return -1;
}

void setSymbolValue(int idx, int value) { tablaS[idx].Value = value; }

int eatComment(FILE* file) {
  int c = fgetc(file);
  if (c == EOF) return 0;
  if (c != ';') {
    ungetc(c, file);
    return 1;
  }
  do {
    c = fgetc(file);
    if (c == EOF) return 0;
  } while (c != '\n');
  return 1;
}

void processMnemonic(FILE* file, char* line, int numread, bool* code,
                     int srcline, int counter) {
  int id = findStr(line, mnemonics, NUMINS);
  if (id == -1) {
    *code = false;
    if ((strncmp("equ", line, numread) == 0) ||
        (strncmp("EQU", line, numread) == 0)) {
      int cte, num;
      num = fscanf(file, " %i", &cte);
      if (num == 1) {
        int idx = getSymbolIdx(srcline);
        if (idx >= 0) setSymbolValue(idx, cte);
      }
    } else {
      printf("Nemónico no reconocido en la línea: %u\n", srcline);
    }
  } else {
    *code = true;
    memcpy(instrucc, opcodes[id], strlen(opcodes[id]));
    size_t numoper = strlen(operands[id]);
    if (numoper == 0) return;
    long int posfile;
    char fmtStr[MAXLINE + 1] = "";
    char fmtStrSym[MAXLINE + 1] = "";
    int num;
    int ops[MAXNUMOPER] = {0, 0, 0};
    char simb[MAXSYMBOLLEN + 1] = "";
    strcat(fmtStr, " ");
    strcat(fmtStrSym, " ");
    for (int i = 0; i < (int)numoper; i++) {
      switch (operands[id][i]) {
        case 'R':
          strcat(fmtStr, "%*[Rr]%2u");
          if (i != (int)(numoper - 1)) strcat(fmtStr, " , ");
          num = fscanf(file, fmtStr, &(ops[i]));
          if (num != 1) {
            printf("Error operando %d reg en línea %d\n", i + 1, srcline);
            exit(1);
          }
          break;
        case 'C':
        case 'D':
          posfile = ftell(file);
          strcat(fmtStr, "%i");
          if (i != (int)(numoper - 1)) strcat(fmtStr, " , ");
          num = fscanf(file, fmtStr, &(ops[i]));
          if (num != 1) {
            fseek(file, posfile, SEEK_SET);
            strcat(fmtStrSym, "%[^ ,\n\r\t\v\f]");
            if (i != (int)(numoper - 1)) strcat(fmtStrSym, "%*[ ,\t]");
            num = fscanf(file, fmtStrSym, simb);
            if (num == 1) {
              int val = getSymbolValue(simb);
              if (val != -1)
                ops[i] = val;
              else
                addSymbRef(simb, srcline, counter, posoper[id][i],
                           operNumBits(id, i));
            } else {
              printf("Error operando %d cte en línea %d\n", i + 1, srcline);
              exit(1);
            }
          }
          break;
      }
      convBin(ops[i], instrucc + (INSTSIZE - 1) - posoper[id][i],
              operNumBits(id, i));
      *fmtStr = '\0';
      *fmtStrSym = '\0';
    }
  }
}

int processLine(FILE* file, bool* code, int* currentline, int counter) {
  char line[MAXLINE + 1];
  int c;
  int numread = 0;
  char* ptchar = line;
  bool isSymbol = false;
  bool isMnemonic = false;
  do {
    c = fgetc(file);
    if (c == EOF) {
      if (isMnemonic) {
        *ptchar = '\0';
        processMnemonic(file, line, numread, code, *currentline, counter);
        return 1;
      }
      return 0;
    }
    if (c == ';') {
      if (isMnemonic) {
        *ptchar = '\0';
        processMnemonic(file, line, numread, code, *currentline, counter);
      }
      ungetc(c, file);
      return eatComment(file) ? 2 : (isMnemonic ? 1 : 0);
    }
    if ((c == ':') && !isSymbol) {
      if (numread > 0) {
        *ptchar = '\0';
        addSymbol(line, counter, *currentline);
      }
      isMnemonic = 0;
      isSymbol = 1;
      ptchar = line;
      numread = 0;
      continue;
    }
    if (isspace(c)) {
      if (c == '\n' || c == '\r') {
        if (c == '\r') {
          int next = fgetc(file);
          if (next != '\n' && next != EOF) ungetc(next, file);
        }
        if (isMnemonic) {
          *ptchar = '\0';
          processMnemonic(file, line, numread, code, *currentline, counter);
        }
        return 2;
      }
      if (isMnemonic) {
        *ptchar = '\0';
        processMnemonic(file, line, numread, code, *currentline, counter);
        isMnemonic = 0;
        continue;
      }
      continue;
    }
    if (!isMnemonic) isMnemonic = true;
    *ptchar++ = (unsigned char)tolower(c);
    numread++;
  } while (numread <= MAXLINE);
  exit(1);
}

int eatWhitespaceAndComments(FILE* file, int* linecount) {
  int c;
  do {
    c = fgetc(file);
    if (c == EOF) return 0;
    if (!isspace(c)) {
      ungetc(c, file);
      if (c == ';') {
        if (!eatComment(file))
          return 0;
        else
          (*linecount)++;
      } else
        return 1;
    } else {
      if (c == '\n' || c == '\r') {
        (*linecount)++;
        if (c == '\r') {
          int next = fgetc(file);
          if (next != '\n' && next != EOF) ungetc(next, file);
        }
      }
    }
  } while (1);
}

void ensambla(const char* srcfilename, const char* dstfilename) {
  FILE *infile, *outfile;
  int counter = 0;
  int currentline = 1;
  bool codEmitido = false;
  if ((infile = fopen(srcfilename, "r")) == NULL) {
    printf("ERROR: src file '%s' open failed\n", srcfilename);
    exit(1);
  }
  memset(progmem, '0', MAXPROGRAMLEN * (INSTSIZE + 1));
  for (int i = 0; i < MAXPROGRAMLEN; i++)
    *((char*)progmem + i * (long long)(INSTSIZE + 1) + INSTSIZE) = '\0';
  int res;
  int seguirflag = 1;
  do {
    if (eatWhitespaceAndComments(infile, &currentline)) {
      memset(instrucc, '0', INSTSIZE);
      instrucc[INSTSIZE] = '\0';
      codEmitido = false;
      res = processLine(infile, &codEmitido, &currentline, counter);
      if (res == 2)
        currentline++;
      else
        seguirflag = 0;
      if (codEmitido && (counter < MAXPROGRAMLEN)) {
        strncpy(progmem[counter], instrucc, INSTSIZE + 1);
        counter++;
      }
    } else
      break;
  } while (seguirflag);
  for (int i = 0; i < numRefs; i++) {
    int value = getSymbolValue(tablaR[i].Symbol);
    if (value == -1) {
      printf("Símbolo %s en línea %u no resuelto\n", tablaR[i].Symbol,
             tablaR[i].LineRef);
      continue;
    }
    convBin(value,
            progmem[tablaR[i].PosRef] + (INSTSIZE - 1) - tablaR[i].BitPos,
            tablaR[i].Size);
  }
  if ((outfile = fopen(dstfilename, "w")) == NULL) {
    printf("ERROR: dest file open failed\n");
    exit(1);
  }
  for (int i = 0; i < counter; i++) fprintf(outfile, "%s\n", progmem[i]);
  fclose(outfile);
}

int main(int argc, char* argv[]) {
  const char* inputFile = "test.asm";
  const char* outputFile = "test.mem";
  if (argc == 2)
    inputFile = argv[1];
  else if (argc == 3) {
    inputFile = argv[1];
    outputFile = argv[2];
  } else if (argc > 3) {
    printf("Uso: %s [entrada] [salida]\n", argv[0]);
    exit(EXIT_FAILURE);
  }
  ensambla(inputFile, outputFile);
}