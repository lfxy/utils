#include <stdio.h>

int* reorder(int* pnum, int len)
{
    if(!pnum || len == 0)
    {
        return pnum;
    }

    int* pstart = pnum;
    int* pend = pnum + len - 1;
    while(pstart < pend)
    {
        while(pstart < pend && (*pstart & 0x1) != 0)
        {
            ++pstart;
        }

        while(pstart < pend && (*pend & 0x1) == 0)
        {
            --pend;
        }

        if(pstart < pend)
        {
            int tmp = *pstart;
            *pstart = *pend;
            *pend = tmp;
        }
    }

    return pnum;
}


int main()
{

    int num[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    for(int i = 0; i < 10; ++i)
    {
        printf("%d,", num[i]);
    }
    printf("\n");
    reorder(num, 10);
    for(int i = 0; i < 10; ++i)
    {
        printf("%d,", num[i]);
    }
    printf("\n");
    return 0;
}

