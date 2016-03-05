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

int main()
{
    FullSort(8);
}
