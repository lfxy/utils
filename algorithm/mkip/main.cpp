#include "stdio.h"
char* ipList[4];
int id[3];
void splite(char* pstr,char* pBegin, int id)
{
    if(id == 3)
    {
        for(int i = 0; i < 3; i++)
        {
            ipList[i] = id[i+1] - id[i];
        }

        for(int i = 0; i < 4; i++)
        {
            printf("%s", ipList[i]);
            ipList[i] == '';
            if(i != 3)
            {
                printf(".");
            }
        }
    }
    else
    {
        for(char* pch=pBegin; *pch != '\0'; ++pch)
        {
            id[id] = pch - pBegin;
            splite(pstr, pBegin+1, id+1);
        }
    }
}

void GetRealIp(char* pstr)
{
    if(pstr == NULL)
        return
    splite(pstr, pstr, 0);
}

int main()
{
	char* lists = "1230498598";
    GetRealIp(lists);
}
