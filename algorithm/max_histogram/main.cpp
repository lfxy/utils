#include <stack>
#include <stdio.h>


int Max(int a, int b)
{
    return a>b?a:b;
}


int maxHistogramArea(int height[], int n)
{
    int max = 0;
    std::stack<int> bars;
    bars.push(-1);
    for(int i = 0; i < n; i++)
    {
        int prev = bars.top();
        if(prev < 0 || height[i] >= height[prev])
        {
            bars.push(i);

        }
        else
        {
            prev = bars.top();
            bars.pop();
            max = Max(max, height[prev] * (i - bars.top() - 1));
            --i;
        }
    }

    while(bars.top() != -1)
    {
        int prev = bars.top();
        bars.pop();
        max = Max(max, height[prev] * (n - bars.top() - 1));
    }
    return max;
}


int main()
{
    int height[6] = {2, 1, 5, 6, 2, 3};
    int ret = 0;

    ret = maxHistogramArea(height, 6);
    printf("ret:%d\n", ret);

    return 0;
}
