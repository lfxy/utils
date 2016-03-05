#include <stdio.h>
#include <stack>

bool checkOutStack(int* pushlist, int* poplist, int length)
{
    if(pushlist == NULL || poplist == NULL || length <= 0)
        return false;

    const int* pushtmp = pushlist;
    const int* poptmp = poplist;
    std::stack<int> pushstack;
    while(poptmp - poplist < length)
    {
        while(pushstack.empty() || pushstack.top() != *poptmp)
        {
            pushstack.push(*pushtmp);
            if(pushtmp - pushlist == length)
                break;

            ++pushtmp;
        }

        if(pushstack.top() != *poptmp)
            return false;
        else
        {
            pushstack.pop();
            ++poptmp;
        }

    }

    return true;
}

int main()
{
    int push_list[5] = { 1, 2, 3, 4, 5 };
    int pop_list[5] = { 3, 4, 5, 2, 1 };
    if(checkOutStack(push_list, pop_list, 5))
        printf("Right!\n");
    else
        printf("Wrong!\n");

    return 0;
}
