/*
 * asm.c
 * Ensamblador configurable v0.3
 * Diseño de Procesadores
 *
 */
#include <ctype.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*Var globales*/

// Definición del lenguaje ensamblador

// Tamaño en bits de la instrucción
#define INSTSIZE 16

// Nemónico de cada instrucción, no puede haber dos iguales
const char* mnemonics[] = {"j",   "jz",  "jnz", "li", "mov", "not",
                           "add", "sub", "and", "or", "neg", "nop"};

// Opcode de cada instrucción
const char* opcodes[] = {"000000", "000001", "000010", "0100",
                         "1000",   "1001",   "1010",   "1011",
                         "1100",   "1101",   "1110",   "001111"};

// Operandos

// Número máximo de operandos posibles en una instrucción
#define MAXNUMOPER 3

// Codificación de los operandos de cada instrucción
// C: cte datos, D: cte de dirección de código, R: campo de registro
const char* operands[] = {"D",   "D",   "D",   "CR",  "RRR", "RRR",
                          "RRR", "RRR", "RRR", "RRR", "RRR"};

// Tamaños de operando
// Tamaño en bits de una constante C (o dirección de datos si así se considera)
#define CONSTANTSIZE 8
// Tamaño en bits de un campo de registro R
#define REGFIELDSIZE 4
// Tamaño en bits de un campo de registro R
#define DESTDIRSIZE 10

// Número de instrucciones deducido de la matriz de nemónicos
#define NUMINS (sizeof(mnemonics) / sizeof(mnemonics[0]))

// Posiciones del bit más significativo de cada operando en la instrucción
// codificada 0 significa no usado
const int posoper[NUMINS][MAXNUMOPER] = {
    {9, 0, 0},  {9, 0, 0},  {9, 0, 0},  {11, 3, 0}, {11, 7, 3}, {11, 7, 3},
    {11, 7, 3}, {11, 7, 3}, {11, 7, 3}, {11, 7, 3}, {11, 7, 3}};

//*************************************************************************************************************************************************************************
// Normalmente no sería necesario tocar el código de más abajo para adaptar a un
// ensamblador nuevo, salvo código de proceso de operandos nuevos como salto
// relativo
//*************************************************************************************************************************************************************************

#define MAXLINE 256  // Tamaño máximo de una línea de ensamblador en caracteres

constexpr auto MAXPROGRAMLEN =
    (1 << DESTDIRSIZE);  // Tamaño máximo de la memoria de programa en palabras
char progmem[MAXPROGRAMLEN][INSTSIZE + 1];
char instrucc[INSTSIZE + 1];

// Contador de posición de memoria actual ($ en muchos ensambladores)
int counter = 0;

// Tabla de Referencias simple, cada una un elemento del array
constexpr auto MAXSYMBOLLEN =
    50;  // Tamaño máximo de un símbolo (Etiqueta o Constante) en caracteres
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

// Tabla de símbolos
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
      return CONSTANTSIZE;  // Tamaño en bits de una Constante
      break;
    case 'R':
      return REGFIELDSIZE;  // Tamaño en bits necesario para codificar un
                            // Registro
      break;
    case 'D':
      return DESTDIRSIZE;  // Tamaño en bits necesario para codificar una
                           // Etiqueta (Destino de un salto)
      break;
    default:
      return -1;
  }
}

void convBin(unsigned int number, char* destStr, size_t numchars) {
  unsigned int numero = number;
  for (int i = 0; i < numchars; i++) {
    if (numero % 2) {
      *(destStr + numchars - 1 - i) = '1';
    } else {
      *(destStr + numchars - 1 - i) = '0';
    }
    numero >>= 1;
  }
}

int findStr(const char* str, const char** liststr, int nelem) {
  int i;
  for (i = 0; i < nelem; i++) {
    if (strcmp(liststr[i], str) == 0) {
      return i;
    }
  }
  return -1;
}

void addSymbRef(const char* sym, int line, int pos, int bitpos, int numbits) {
  if (numRefs < MAXSYMBREFS) {
    strcpy_s(tablaR[numRefs].Symbol, MAXSYMBOLLEN + 1, sym);
    tablaR[numRefs].LineRef = line;
    tablaR[numRefs].PosRef = pos;
    tablaR[numRefs].BitPos = bitpos;
    tablaR[numRefs].Size = numbits;
    // printf("Insert. ref. a símbolo: '%s' ocurrida en la línea fuente %u
    // (instrucción en dir %u) en idx %u de tabla de referencias\n", sym, line,
    // pos, numRefs);
    numRefs++;
  } else {
    printf("Tabla de Referencias llena intentando añadir: '%s'\n", sym);
  }
}

void addSymbol(const char* sym, int value, int srcline) {
  if (numSymb < MAXSYMBOLS) {
    strcpy_s(tablaS[numSymb].Symbol, MAXSYMBOLLEN + 1, sym);
    tablaS[numSymb].Value = value;
    tablaS[numSymb].LineDef = srcline;
    // printf("Insertando símbolo: '%s' con valor %u en pos %u de tabla de
    // simbolos\n", sym, value, numSymb);
    numSymb++;
  } else {
    printf("Tabla de símbolos llena intentando añadir: '%s'\n", sym);
  }
}

int getSymbolIdx(int lineadef) {
  int idx = -1;
  for (int i = 0; i < numSymb; i++) {
    if (tablaS[i].LineDef == lineadef) {
      idx = i;
      break;
    }
  }
  return idx;
}

int getSymbolValue(const char* sym) {
  int value = -1;
  for (int i = 0; i < numSymb; i++) {
    if (!strncmp(tablaS[i].Symbol, sym, strlen(sym))) {
      value = tablaS[i].Value;
      break;
    }
  }
  // printf("Buscando valor del simbolo '%s' y obtenido %d\n", sym, value);
  return value;
}

void setSymbolValue(int idx, int value) {
  tablaS[idx].Value = value;
  // printf("Asignando al símbolo con ind=%u '%s' el valor %u\n",idx,
  // tablaS[idx].Symbol, value);
}

// Comentarios iniciados con ";", los elimina hasta el final de la línea
int eatComment(FILE* file) {
  // Devuelve 0 si se ha acabado el fichero procesando el comentario, 1 si no
  int c;
  c = fgetc(file);
  if (c == EOF) {
    return 0;
  }
  if (c != ';') {
    ungetc(c, file);  // Por si se ha llamado sin determinar si era comentario
    return 1;
  } else {  // Procesa el resto del comentario hasta fin de linea
    do {
      c = fgetc(file);
      if (c == EOF) {
        return 0;
      }
    } while (
        c !=
        '\n');  // Se asume que no se abre en modo binario (Windows compatible)
  }
  return 1;
}

void processMnemonic(FILE* file, char* line, int numread, bool* code,
                     int srcline, int counter) {
  int id = findStr(line, mnemonics, NUMINS);
  if (id == -1) {  // No es nemónico, posible pseudoint o error
    *code = false;
    if ((strncmp("equ", line, numread) == 0) ||
        (strncmp("EQU", line, numread) ==
         0)) {  // Caso 'equ' (única pseudo ins por el momento)
      int cte, num;
      num = fscanf_s(file, " %i", &cte);
      // printf("Avanzado el puntero de fichero a %ld\n", ftell(file));
      if (num == 1) {
        int idx = getSymbolIdx(srcline);
        if (idx < 0) {
          printf("No hay símbolo definido para el 'equ' en la línea: %u\n",
                 srcline);
        } else {
          setSymbolValue(idx, cte);
        }
      } else {
        printf("Operando incorrecto para el 'equ' en la línea: %u\n", srcline);
      }
    } else {
      printf("Nemónico no reconocido en la línea: %u\n", srcline);
    }
  } else {         // Es nemonico
    *code = true;  // Se va a emitir código
    // Lo guardamos en la linea de código máquina actual instrucc
    memcpy(instrucc, opcodes[id], strlen(opcodes[id]));
    // Veamos el número de operandos esperado
    size_t numoper = strlen(operands[id]);
    if (numoper == 0) {  // se acabó de momento
      return;
    }
    // Procesamos operandos
    long int posfile;                  // Posicion del fichero de entrada
    char fmtStr[MAXLINE + 1] = "";     // Cadena de formato scanf de operandos
    char fmtStrSym[MAXLINE + 1] = "";  // Igual para operandos con símbolos
    int num;  // Valor devuelto pos scanf como numero de operandos reconocidos
    int ops[MAXNUMOPER] = {
        0, 0,
        0};  // Operandos posibles, máximo tres operandos reales de los cuales
             // solo uno puede ser un simbolo que se resolverá o no ahora
    char simb[MAXSYMBOLLEN + 1] = "";       // símbolo
    strncat_s(fmtStr, MAXLINE, " ", 1);     // Permitimos ws iniciales
    strncat_s(fmtStrSym, MAXLINE, " ", 1);  // Permitimos ws iniciales
    for (int i = 0; i < numoper; i++) {     // Procesamos cada tipo de operando?
      switch (operands[id][i]) {
        case 'R':
          strcat_s(fmtStr, MAXLINE,
                   "%*[Rr]%2u");  // Registros, intentar leer dos caracteres de
                                  // num. registro máximo
          if (i != (numoper - 1))
            strcat_s(fmtStr, MAXLINE,
                     " , ");  // Si no somos el último operando, consumir ws y
                              // coma enmedio
          num = fscanf_s(file, fmtStr, &(ops[i]));
          // printf("Avanzado al leer cte o no el puntero de fichero a %ld\n",
          // ftell(file));
          if (num != 1) {
            printf(
                "Error buscando operando %d tipo registro con formato '%s' en "
                "línea %d\n",
                i + 1, fmtStr, srcline);
            exit(1);
          }
          break;
        case 'C':
        case 'D':
          // Podría ser simbólico, intentamos primero con ctes
          posfile = ftell(file);  // guardar posición del fichero de entrada
          strcat_s(fmtStr, MAXLINE,
                   "%i");  // Permite leer en hex, octal o decimal con notación
                           // del C,valores negativos en decimal (se codificarán
                           // en complemento a 2)
          if (i != (numoper - 1))
            strcat_s(fmtStr, MAXLINE,
                     " , ");  // Si no somos el último operando, consumir ws y
                              // coma enmedio
          num = fscanf_s(file, fmtStr, &(ops[i]));
          // printf("Avanzado al leer cte o no el puntero de fichero a %ld\n",
          // ftell(file));
          if (num != 1) {                    // No se pudo leer bien el operando
            fseek(file, posfile, SEEK_SET);  // restauramos pos en fichero
            // printf("Retrocedido el puntero a %ld\n", ftell(file));
            strcat_s(fmtStrSym, MAXLINE,
                     "%[^ ,\n\t]");  // Leer símbolo como cadena a ver
            if (i != (numoper - 1))
              strcat_s(fmtStrSym, MAXLINE,
                       "%*[ ,\t]");  // si no somos ultimo operando quita
                                     // espacios, tabs y coma siguientes
            num = fscanf_s(file, fmtStrSym, simb, MAXSYMBOLLEN);
            // printf("Avanzado al leer simbolo el puntero de fichero a %ld\n",
            // ftell(file));
            if (num ==
                1) {  // Ha habido suerte, ahora recuperar el valor del símbolo
              int val = getSymbolValue(simb);
              if (val != -1) {  // Encontrado
                ops[i] = val;
              } else {  // No encontrado, meter en tabla de referencias para
                        // resolverlas al final
                addSymbRef(simb, srcline, counter, posoper[id][i],
                           operNumBits(id, i));
              }
            } else {
              printf(
                  "Error buscando operando %d cte con formato '%s' en la línea "
                  "%d\n",
                  i + 1, fmtStrSym, srcline);
              exit(1);
            }
          }
          break;
        default:
          break;
      }
      if (num != 1) {
        printf("Error buscando operando %d en la línea %d\n", i + 1, srcline);
        exit(1);
      }
      // Ahora convertimos el operando cte, de registro o simbolico resuelto en
      // instrucc (el no resuelto estará a cero)
      convBin(ops[i], instrucc + (INSTSIZE - 1) - posoper[id][i],
              operNumBits(id, i));

      // Inicializa cadenas de formato de siguientes operandos
      *fmtStr = '\0';
      *fmtStrSym = '\0';
    }
    // Ahora tenemos la instrucción completa salvo los símbolos que no han
    // podido ser resueltos (quedan a cero)
  }
}

int processLine(FILE* file, bool* code, int* currentline, int counter) {
  // devuelve 2 para fin de procesado de linea normal,
  //          1 para fin de fichero con linea procesada lista,
  //          0 para fin de fichero sin linea procesada
  // Los ws deben ser consumidos antes, esperamos entrar con caracter no ws
  char line[MAXLINE + 1];
  int c;
  int numread = 0;
  char* ptchar = line;
  bool isSymbol = false;
  bool isMnemonic = false;  // Suposiciones iniciales
  // printf("Procesando Línea %d \n", *currentline);
  do {
    c = fgetc(file);
    // printf("Leido caracter:'%c' de la pos fichero:%ld\n", c, ftell(file));
    // printf("L:%c\n", c);
    if (c == EOF) {  // Caso de error o de fin de fichero, línea finalizada en
                     // todo caso
      if (isMnemonic) {  // Si estabamos procesando la cadena de un nemonico sin
                         // operandos
        *ptchar = '\0';  // Acaba la cadena en line
        processMnemonic(file, line, numread, code, *currentline,
                        counter);  // Procesalo y finaliza linea
        return 1;
      } else {
        return 0;
      }
    }
    if (c == ';') {  // Comentario, no hay nada más hasta final de línea, puede
                     // acabar nemonico sin operandos
      if (isMnemonic) {  // Si estabamos procesando la cadena de un nemonico
        *ptchar = '\0';  // Acaba la cadena en line
        processMnemonic(file, line, numread, code, *currentline,
                        counter);  // Procesalo y sigue con el comentario
        ungetc(c, file);
        if (!eatComment(
                file)) {  // EOF, salimos indicando que posiblemente hay línea
          return 1;       // EOF con el nemonico posiblemente procesado
        } else {
          return 2;  // Sigue fichero normal, posiblemente linea procesada
        }
      } else {
        ungetc(c, file);
        if (!eatComment(file)) {  // Los consume, incluyendo el fin de línea
          return 0;               // EOF con nada pendiente
        } else {
          return 2;  // Sigue fichero normal, posiblemente linea procesada
        }
      }
    }
    if ((c == ':') && (isSymbol == false)) {  // fin de simbolo y no encontrado
                                              // antes (no se chequea su cadena)
      if (numread > 0) {
        *ptchar = '\0';  // Acaba la cadena
        addSymbol(line, counter, *currentline);
      } else {
        printf("Leída definición de símbolo vacío en línea: %d\n",
               *currentline);
      }
      isMnemonic = 0;  // Permite leer futuro nemónico
      isSymbol = 1;    // Impide volver a leer una etiq en esta línea
      ptchar = line;   // prepara el buffer para recibir de nuevo
      numread = 0;
      continue;  // no tener en cuenta el caracter actual ':' como valido
    }
    if (isspace(c)) {
      // Pueden ser espacios entre etiq y nemonico, previos a un nemonico solo,
      // o espacios en linea sin elem importantes
      if (c == '\n') {
        if (isMnemonic) {  // Si estabamos procesando la cadena de un nemonico
                           // sin operandos
          *ptchar = '\0';  // Acaba la cadena en line
          processMnemonic(file, line, numread, code, *currentline,
                          counter);  // Procesalo y termina linea
        }
        return 2;  // Fin de línea normal
        //*currentline = *currentline + 1;
        // break;
      }
      if (isMnemonic) {  // Estamos leyendo una cadena y encontramos un ws, ya
                         // solo puede ser fin de mnemonico
        *ptchar = '\0';  // Acaba la cadena en line
        processMnemonic(
            file, line, numread, code, *currentline,
            counter);    // Procesalo y a la vuelta vemos el resto de la linea
        isMnemonic = 0;  // impide seguir considerando caracteres
        continue;
      } else {     // solo hemos leido ws de momento
        continue;  // no guardamos nada ni cambiamos estado
      }
    }
    /* un caracter valido parte de etiq o nemonico*/
    if (!isMnemonic) {
      isMnemonic = true;
    }
    // Hemos empezado la cadena o seguimos añadiendo caracteres, bien por
    // nemonico real o etiq supuesta nemonico
    *ptchar++ = (unsigned char)tolower(
        c);  // guarda en lowercase caracteres sin espacio
    numread++;
  } while (numread <= MAXLINE);  // Esto es dudoso, ya que aqui no se procesa
                                 // una línea entera, da un poco igual
  printf("ERROR: field too long\n");
  exit(1);
  // Esta vuelta no se alcanzarà, solo con un nemonico o etiqueta excesivamente
  // grande
}

int eatWhitespaceAndComments(FILE* file, int* linecount) {
  // Devuelve true si hemos avanzado en el fichero hasta un caracter no ws que
  // no esté dentro de un comentario
  int c;
  do {
    c = fgetc(file);
    if (c == EOF) {
      return 0;
    }
    if (!isspace(c)) {  // Devuelve el caracter leido al stream
      ungetc(c, file);
      if (c == ';') {
        if (!eatComment(
                file)) {  // Elimina el comentario (hasta final de la línea)
          return 0;
        } else {
          // printf("Línea %d de Comentario procesado\n", *linecount);
          (*linecount)++;
        }
      } else {
        return 1;
      }
    } else {
      if (c == '\n') {
        // printf("Línea %d en blanco procesada\n", *linecount);
        (*linecount)++;
      }
    }
  } while (1);
}

void ensambla(const char* srcfilename, const char* dstfilename) {
  FILE *infile, *outfile;
  int counter = 0;
  int currentline = 1;
  bool codEmitido = false;

  if (fopen_s(&infile, srcfilename, "r") != 0) {
    printf("ERROR: src file '%s' open failed\n", srcfilename);
    exit(1);
  }

  // Inicializa toda la memoria de programa a '0':
  memset(progmem, '0', MAXPROGRAMLEN * (INSTSIZE + 1));
  for (int i = 0; i < MAXPROGRAMLEN; i++) {
    *((char*)progmem + i * (long long)(INSTSIZE + 1) + INSTSIZE) =
        '\0';  // Cada instrucción como una cadena con "0"s acabada en '\0'
  }

  // Ahora por cada línea de código fuente
  int res;
  int seguirflag = 1;
  do {
    if (eatWhitespaceAndComments(
            infile, &currentline)) {  // quita espacios y comentarios previos
                                      // actualizando el numero de linea
      memset(instrucc, '0',
             INSTSIZE);  // Preparar el buffer de la instrucción todo a "0"
      instrucc[INSTSIZE] = '\0';
      codEmitido = false;
      res = processLine(infile, &codEmitido, &currentline, counter);
      if (res == 2) {
        currentline++;
      } else {
        seguirflag = 0;
      }
      // printf("I: %s\n", instrucc);
      if (codEmitido && (counter < MAXPROGRAMLEN)) {
        // printf("Copiando la cadena de instrucc %s de tamaño %zu sobre la
        // cadena de contenido ->%s<-\n", instrucc, strlen(instrucc), (char
        // *)progmem[counter]);
        strcpy_s(progmem[counter], INSTSIZE + 1, instrucc);
        // printf("Programa en dir %u es instrucc %s\n",counter,
        // progmem[counter]);
        counter++;
      }
    } else {  // Se llegó al final del fichero eliminando espacios y comentarios
      break;
    }
  } while (seguirflag);
  // Resolver los símbolos pendientes
  for (int i = 0; i < numRefs; i++) {
    // buscamos el símbolo
    int value = getSymbolValue(tablaR[i].Symbol);
    if (value == -1) {
      printf("Símbolo %s que aparece en la línea %u no resuelto\n",
             tablaR[i].Symbol, tablaR[i].LineRef);
      continue;
    }
    convBin(value,
            progmem[tablaR[i].PosRef] + (INSTSIZE - 1) - tablaR[i].BitPos,
            tablaR[i].Size);
  }

  if (fopen_s(&outfile, dstfilename, "w") != 0)  // Se abre en modo texto
  {
    printf("ERROR: dest file open failed\n");
    exit(1);
  } else {
    if (outfile != NULL) {
      for (int i = 0; i < counter; i++) {
        fprintf(outfile, "%s\n", progmem[i]);
      }
      fclose(outfile);
    }
  }
}

int main(int argc, char* argv[]) {
  setlocale(LC_ALL,
            ".UTF-8");  // Configura UTF-8 para mostrar caracteres no ascii
  const char* inputFile =
      "test.asm";  // Valor por defecto para el archivo de entrada
  const char* outputFile =
      "test.mem";  // Valor por defecto para el archivo de salida

  // Si se especifica solo un argumento adicional, se asume que es el archivo de
  // entrada
  if (argc == 2) {
    inputFile = argv[1];
  }
  // Si se especifican dos argumentos, el primero es el archivo de entrada y el
  // segundo el de salida
  else if (argc == 3) {
    inputFile = argv[1];
    outputFile = argv[2];
  }
  // Si hay más de dos argumentos, informar al usuario sobre el uso correcto del
  // programa
  else if (argc > 3) {
    printf("Uso: %s [archivo_entrada] [archivo_salida]\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  ensambla(inputFile, outputFile);
}
