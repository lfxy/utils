#include <stdio.h>
#include <string>
#include <vector>

typedef struct _dTree
{
    struct _dTree* pleft;
    struct _dTree* pright;
    int value;
}dTree;

 dTree* makeTree(int& startValue, int level)
{
    if(level <= 0)
    {
        printf("-----------------------\n");
        return NULL;
        //node->value = startValue;
        //node->pleft = NULL;
        //node->pright = NULL;
        //printf("0:%d\n", startValue);
    }
    else
    {
        dTree* node = new dTree;
        --level;
        node->value = startValue;
        printf("1:%d\n", startValue);
        startValue++;
        node->pleft = makeTree(startValue, level);
        node->pright = makeTree(startValue, level);
        return node;
    }
}

void printTree(dTree* startnode, bool bdelete = false)
{
    if(startnode == NULL)
    {
        //printf("\n");
        return;
    }
    else
    {
        printf("%d,", startnode->value);
        printTree(startnode->pleft);
        printTree(startnode->pright);
        if(bdelete)
            delete startnode;
    }
}

void checkSum(dTree* pnode, int sum, std::vector<int>& tmpvec, int& tmpSum)
{
    if(pnode == NULL)
        return;
    
    tmpvec.push_back(pnode->value);
    tmpSum += pnode->value;
    bool bfnode = false;
    bfnode = pnode->pleft == NULL && pnode->pright == NULL;

    if(tmpSum == sum && bfnode)
    {
        printf("has path:");
        for(int i = 0; i < tmpvec.size(); ++i)
        {
            printf("%d", tmpvec[i]);
        }
        printf("\n");
    }

    if(tmpSum < sum)
    {
        if(pnode->pleft)
            checkSum(pnode->pleft, sum, tmpvec, tmpSum);
        if(pnode->pright)
            checkSum(pnode->pright, sum, tmpvec, tmpSum);
    }
    tmpSum -= pnode->value;
    tmpvec.pop_back();
}


void findSum(dTree* pRoot, int sum)
{
    if(pRoot == NULL)
        return;

    std::vector<int> tmpvec;
    int tmpsum = 0;
    checkSum(pRoot, sum, tmpvec, tmpsum);
}


int main()
{
    int svalue = 0;
    dTree* rootnode = makeTree(svalue, 3);
    printTree(rootnode);
    printf("\n");
    findSum(rootnode, 10);
    return 0;
}
