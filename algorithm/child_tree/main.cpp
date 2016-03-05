#include <stdio.h>
#include <string>

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

bool checkRestNode(dTree* rootNode, dTree* childNode)
{
    if(childNode == NULL)
        return true;
    if(rootNode == NULL)
        return false;

    if(rootNode->value == childNode->value)
        return checkRestNode(rootNode->pleft, childNode->pleft) && checkRestNode(rootNode->pright, childNode->pright);
    else
        return false;
}

bool isChildNode(dTree* rootNode, dTree* childNode)
{
    if(rootNode == NULL || childNode == NULL)
    {
        return false;
    }

    bool ischild = false;
    if(rootNode->value == childNode->value)
        ischild = checkRestNode(rootNode->pleft, childNode->pleft) && checkRestNode(rootNode->pright, childNode->pright);

    if(!ischild)
        ischild = isChildNode(rootNode->pleft, childNode);

    if(!ischild)
        ischild = isChildNode(rootNode->pright, childNode);

    return ischild;
}

int main()
{
    int svalue = 0;
    dTree* rootnode = makeTree(svalue, 5);
    printTree(rootnode);
    printf("\n");
    svalue = 13;
    dTree* childnode = makeTree(svalue, 2);
    /*
    dTree childnode;
    dTree childnode1;
    dTree childnode2;
    childnode.value = 2;
    childnode1.value = 3;
    childnode2.value = 6;
    childnode.pleft = &childnode1;
    childnode.pright = &childnode2;
    childnode1.pleft = NULL;
    childnode1.pright = NULL;
    childnode2.pleft = NULL;
    childnode2.pright = NULL;
    */
    printTree(childnode);
    printf("\n");
    if(isChildNode(rootnode, childnode))
        printf("is child node!\n");
    else
        printf("is not child node!\n");

    printTree(rootnode, true);
    printf("\n");
    std::string test;
    std::string base = "111";
    test = "/" + base + "aa";
    printf("test:%s\n", test.c_str());
    return 0;
}
