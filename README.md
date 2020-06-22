# Valor mínimo, máximo e soma dos produtos escalares de duas matrizes

Programa em CUDA que utiliza os conceitos de operações atômicas e também de múltiplas streams para calcular o menor valor presente em duas matrizes inseridas através de um arquivo

Exemplo de arquivo de matrizes:

3

11 2 3

4 5 6

7 8 9

19 8 7

6 5 4

3 2 1

Onde a **primeira linha representa a dimensão das matrizes**.

Para executar o programa, primeiro compile

$ nvcc -o desafio desafio.cu 

Em seguida

$ ./desafio <nome da entrada txt>
