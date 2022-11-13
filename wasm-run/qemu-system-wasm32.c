#include <unistd.h>

int main(int argc, char *argv[]) {
  argv[0] = WASM_RUN;
  execv(argv[0], argv);
}
