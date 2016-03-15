#include <stdio.h>


void inSort(char* str, char* begin)
{
    if(*begin == '\0')
    {
        printf("%s\n", str);
    }
    else
    {
        for(char* ptr = begin; *ptr != '\0'; ++ptr)
        {
            char tmp = *ptr;
            *ptr = *begin;
            *begin = tmp;

            inSort(str, begin + 1);

            tmp = *ptr;
            *ptr = *begin;
            *begin = tmp;
        }
    }

}

void stringSort(char* str)
{
    if(str == NULL)
        return;

    inSort(str, str);
}

int main()
{
    //char* forsort = "abc";
    char forsort[] = "abc";
    stringSort(forsort);
    return 0;
}
