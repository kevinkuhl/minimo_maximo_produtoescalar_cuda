#include<stdio.h>
#include<stdlib.h>
#include<cuda_runtime.h>

// Kernel para encontrar o menor valor dado um vetor
__global__ void encontraMenor(int *vetor,int *menor, int tam)
{
        // Calcula a posicao inicial analisada
        int idx = threadIdx.x + blockIdx.x*blockDim.x;
        // Enquanto a posicao for menor do que o limite do vetor
        if (idx < tam)
        {
                // Calcula o elemento minimo, comparando com o valor em menor
                atomicMin(menor,vetor[idx]);
        }
}

// Kernel para encontrar o maior valor dado um vetor
__global__ void encontraMaior(int *vetor,int *maior, int tam)
{
        // Calcula a posicao inicial analisada
        int idx = threadIdx.x + blockIdx.x*blockDim.x;
        // Enquanto a posicao for menor do que o limite do vetor
        if (idx < tam)
        {
                // Calcula o elemento minimo, comparando com o valor em menor
                atomicMax(menor,vetor[idx]);
        }
}

// Kernel para encontrar a soma dos produtos escalares dado um vetor
__global__ void produtoEscalar(int *vetor1, int *vetor2, int *produto, int tam)
{
        // Calcula a posicao inicial analisada
        int idx = threadIdx.x + blockIdx.x*blockDim.x;
        // Enquanto a posicao for menor do que o limite do vetor
        if (idx < tam)
        {
            produto += vetor1[idx] * vetor2[idx];
        }
}

// Funcao para abrir o arquivo e retornar o ponteiro
FILE *abrir_arquivo(char nome[])
{
        FILE *pFile;
        pFile = fopen(nome, "r");
        if(pFile==NULL)
                exit(0);
        return pFile;
}

int main(int argc,char **argv)
{
        if(argc < 2)
            printf("Para utilizar, rode o comando ./calc_matriz <nome da entrada txt>\n");
        // Define as variaveis a serem utilizadas
        FILE *file;
        int *mA_h,*mB_h;
        int *mA_d,*mB_d;

        // Dimensoes das matrizes a serem lidas
        int dimensao;

        // Variaveis de iteracao
        int i,j;

        // Ponteiros para o resultado
        int *menorA_d;
        int *menorA_h;
        int *menorB_d;
        int *menorB_h;
        int *maiorA_d;
        int *maiorA_h;
        int *maiorB_d;
        int *maiorB_h;
        int *produto_h;
        int *produto_d;

        // Definindo as streams
        cudaStream_t stream1, stream2, stream3, stream4, stream5;

        // Criando as streams
        cudaStreamCreate(&stream1);
        cudaStreamCreate(&stream2);
        cudaStreamCreate(&stream3);
        cudaStreamCreate(&stream4);
        cudaStreamCreate(&stream5);

        // Abre o arquivo
        file = abrir_arquivo(argv[1]);

        // Le as dimensoes
        fscanf(file,"%d",&dimensao);

        // Aloca espaco no host para as matrizes e para os resultados
        cudaMallocHost((void**)&mA_h,dimensao*simensao*(sizeof(int)));
        cudaMallocHost((void**)&mB_h,dimensao*simensao*(sizeof(int)));
        cudaMallocHost((void**)&menorA_h,sizeof(int));
        cudaMallocHost((void**)&menorB_h,sizeof(int));
        cudaMallocHost((void**)&maiorA_h,sizeof(int));
        cudaMallocHost((void**)&maiorB_h,sizeof(int));
        cudaMallocHost((void**)&produto_h,sizeof(int));

        // Le as matrizes a partir do arquivo aberto
        for(i=0;i<dimensao;i++)
                for(j=0;j<dimensao;j++)
                        fscanf(file,"%d", &mA_h[i*dimensao+j]);

        for(i=0;i<dimB[0];i++)
                for(j=0;j<dimB[1];j++)
                        fscanf(file,"%d", &mB_h[i*dimensao+j]);
        
        // Fecha o arquivo
        fclose(file);

        // Aloca espaco no device para as matrizes e para os resultados
        cudaMalloc((void**)&mA_d,(dimA[0])*dimA[1]*(sizeof(int)));
        cudaMalloc((void**)&mB_d,(dimB[0])*dimB[1]* (sizeof(int)));
        cudaMalloc((void**)&menorA_d,sizeof(int));
        cudaMalloc((void**)&menorB_d,sizeof(int));
        cudaMalloc((void**)&maiorA_d,sizeof(int));
        cudaMalloc((void**)&maiorB_d,sizeof(int));
        cudaMalloc((void**)&produto_d,sizeof(int));


        // Inicializa o conteúdo do resultado no device com 10000
        cudaMemset(menorA_d,10000,sizeof(int));
        cudaMemset(menorB_d,10000,sizeof(int));
        cudaMemset(maiorA_d,-10000,sizeof(int));
        cudaMemset(maiorB_d,-10000,sizeof(int));
        cudaMemset(produto_d,0,sizeof(int));
        
        // Inicializa as variaveis de thrads por bloco e de blocos por grid
        /* Aqui vale uma ressalva, como as matrizes podem ter dimensoes diferentes
        umas das outras, optamos por utilizar um bloco unico com tamanho total igual
        ao tamanho da matriz (produto das dimensoes).
        Isso evita termos que fazer dois loops for para iterar sobre os blocos (um para cada matriz)
        */
        int threadsPerBlock = dimensao*dimensao;
        int blocksPerGrid = ((dimensao)+threadsPerBlock-1)/threadsPerBlock;

        // Copia asincronamente a memoria do host para o device
        cudaMemcpyAsync(mA_d,mA_h,(dimensao*dimensao*sizeof(int)), cudaMemcpyHostToDevice, stream1);
        cudaMemcpyAsync(mB_d,mB_h,(dimensao*dimensao*sizeof(int)), cudaMemcpyHostToDevice, stream2);
        
        // Chama a funcao para encontrar o minimo na matriz A, utilizando a stream1
        encontraMenor <<<blocksPerGrid,threadsPerBlock,0,stream1>>>(mA_d,menorA_d,dimensao*dimensao);
        // Copia o resultado para o host
        cudaMemcpy(menorA_h,menorA_d,sizeof(int), cudaMemcpyDeviceToHost);

        encontraMaior <<<blocksPerGrid,threadsPerBlock,0,stream2>>>(mA_d,maiorA_d,dimensao*dimensao);
        cudaMemcpy(maiorA_h,maiorA_d,sizeof(int), cudaMemcpyDeviceToHost);

        // Chama a funcao para encontrar o minimo na matriz B, utilizando a stream2
        encontraMenor <<<blocksPerGrid,threadsPerBlock,0,stream3>>>(mB_d,menorB_d,dimensao*dimensao);
        // Copia o resultado para o host
        cudaMemcpy(menorB_h,menorB_d,sizeof(int), cudaMemcpyDeviceToHost);

        encontraMaior <<<blocksPerGrid,threadsPerBlock,0,stream4>>>(mB_d,maiorB_d,dimensao*dimensao);
        cudaMemcpy(maiorB_h,maiorB_d,sizeof(int), cudaMemcpyDeviceToHost);

        produtoEscalar <<<blocksPerGrid,threadsPerBlock,0,stream5>>>(mA_d,mB_d,produto_d,dimensao*dimensao);
        cudaMemcpy(produto_h,produto_d,sizeof(int), cudaMemcpyDeviceToHost);

        // Sincroniza as streams criadas
        cudaStreamSynchronize(stream1);
        cudaStreamSynchronize(stream2);
        cudaStreamSynchronize(stream3);
        cudaStreamSynchronize(stream4);
        cudaStreamSynchronize(stream5);

        // Imprime os resultados
        printf("%d ", *produto_h);
        if(*maiorA_h < *maiorB_h)
            printf("%d ", *maiorB_h);
        else
            printf("%d ", *maiorA_h);
        
        if(*menorA_h < *menorB_h)
            printf("%d\n", *menorA_h);
        else
            printf("%d\n", *menorB_h);


        // Libera o espaco alocado para as variaveis no host
        cudaFreeHost(menorA_h);
        cudaFreeHost(menorB_h);
        cudaFreeHost(maiorA_h);
        cudaFreeHost(maiorB_h);
        cudaFreeHost(mA_h);
        cudaFreeHost(mB_h);
        cudaFreeHost(produto_h);

        // Libera o espaco alocado para as variaveis no device
        cudaFree(mB_d);
        cudaFree(mA_d);
        cudaFree(menorA_d);
        cudaFree(menorB_d);
        cudaFree(maiorA_d);
        cudaFree(maiorB_d);
        cudaFree(produto_d);

        // Libera o espaco alocado para as streams (fecha as streams)
        cudaStreamDestroy(stream1);
        cudaStreamDestroy(stream2);
        cudaStreamDestroy(stream3);
        cudaStreamDestroy(stream4);
        cudaStreamDestroy(stream5);

        // Sai do programa      
        exit(0);
}