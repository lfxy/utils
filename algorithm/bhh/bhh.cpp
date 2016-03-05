#include <stdio.h>

int g_number = 0;
 
void PrintQueen(int ColumnIndex[], int length)
{
    printf("Solution %d\n", g_number);
 
    for(int i = 0; i < length; ++i)
        printf("%d\t", ColumnIndex[i]);
   
    printf("\n");
}

bool Check(int ColumnIndex[], int length)
{
    for(int i = 0; i < length; ++ i)
    {
        for(int j = i + 1; j < length; ++ j)
        {
            if((i - j == ColumnIndex[i] - ColumnIndex[j])
                || (j - i == ColumnIndex[i] - ColumnIndex[j]))
            return false;
        }
    }
 
    return true;
}

void Permutation(int ColumnIndex[], int length, int index)
{
    if(index == length)
    {
        if(Check(ColumnIndex, length))
        {
            ++ g_number;
            //PrintQueen(ColumnIndex, length);
        }
    }
    else
    {
        for(int i = index; i < length; ++ i)
        {
            int temp = ColumnIndex[i];
            ColumnIndex[i] = ColumnIndex[index];
            ColumnIndex[index] = temp;
 
            Permutation(ColumnIndex, length, index + 1);
 
            temp = ColumnIndex[index];
            ColumnIndex[index] = ColumnIndex[i];
            ColumnIndex[i] = temp;
        }
    }
}

void EightQueen()
{
    const int queens = 8;
    int ColumnIndex[queens];
    for(int i = 0; i < queens; ++ i)
        ColumnIndex[i] = i;
 
    Permutation(ColumnIndex, queens, 0);
}
 
int main()
{
    EightQueen();
    printf("Solution %d\n", g_number);
    return 0;
}
