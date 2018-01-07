#include <stdio.h>

void sortby(int nums[], int length, int index, int& count)
{
    if(index >= length - 1)
    {
        ++count;
        //printf("%s\n", nums);
        return;
    }

    for(int i = index; i < 8; ++i)
    {
        int tmp = nums[i];
        nums[i] = nums[index];
        nums[index] = tmp;

        sortby(nums, length, index + 1, count);

        tmp = nums[i];
        nums[i] = nums[index];
        nums[index] = tmp;
    }
}

void FullSort(int n)
{
    if(n <= 0)
    {
        return;
    }
    int* nums = new int[n];
    int count = 0;
    for(int i = 0; i < 8; ++i)
    {
        nums[i] = i;
    }
    sortby(nums, n, 0, count);
    printf("count:%d\n", count);
}

typedef struct node {
    struct node* next;
    int value;
} Node;

Node* MergeList(Node* phead1, Node* phead2)
{
    if(phead1 == NULL)
        return phead2;
    else if(phead2 == NULL)
        return phead1;

    Node* pRetHead = NULL;
    if(phead1->value < phead2->value)
    {
        pRetHead = phead1;
        pRetHead->next = MergeList(phead1->next, phead2);
    }
    else
    {
        pRetHead = phead2;
        pRetHead->next = MergeList(phead1, phead2->next);
    }
    return pRetHead;
}




int main()
{
    FullSort(8);
}
