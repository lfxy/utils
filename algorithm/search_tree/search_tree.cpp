#include <stdio.h>
#include <string>
#include <vector>
#include <stack>

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


void find_tree_preorder1(dTree* startnode)
{
    if(startnode == NULL)
        return;

    std::stack<dTree*> treeStack; 
    dTree* pcurr = startnode;

    while(pcurr != NULL || treeStack.size())
    {
        while(pcurr != NULL)
        {
            printf("%d, ", pcurr->value);
            treeStack.push(pcurr);
            pcurr = pcurr->pleft;
        }
        if(treeStack.size())
        {
            pcurr = treeStack.top();
            treeStack.pop();
            pcurr = pcurr->pright;
        }

    }
    printf("\n");
}

void find_tree_preorder2(dTree* startnode)
{
    if(startnode == NULL)
        return;

    std::stack<dTree*> treeStack; 
    treeStack.push(startnode);
    while(treeStack.size())
    {
        dTree* ptmp = treeStack.top();
        treeStack.pop();
        printf("%d, ", ptmp->value);
        if(ptmp->pright != NULL)
            treeStack.push(ptmp->pright);

        if(ptmp->pleft != NULL)
            treeStack.push(ptmp->pleft);
    }
    printf("\n");
}

void find_tree_inorder1(dTree* startnode)
{
    if(startnode == NULL)
        return;

    std::stack<dTree*> treeStack; 
    dTree* pcurr = startnode;

    while(pcurr != NULL || treeStack.size())
    {
        while(pcurr != NULL)
        {
            treeStack.push(pcurr);
            pcurr = pcurr->pleft;
        }
        if(treeStack.size())
        {
            pcurr = treeStack.top();
            treeStack.pop();
            printf("%d, ", pcurr->value);
            pcurr = pcurr->pright;
        }

    }
    printf("\n");
}


void find_tree_postorder1(dTree* startnode)
{
    std::stack<dTree*> s1;
    dTree* curr = startnode;
    dTree* previsited = NULL;
    while(curr != NULL || s1.size())
    {
        while(curr != NULL)
        {
            s1.push(curr);
            curr = curr->pleft;
        }
        curr = s1.top();
        if(curr->pright == NULL || curr->pright == previsited)
        {
            printf("%d, ", curr->value);
            previsited = curr;
            s1.pop();
            curr = NULL;
        }
        else
        {
            curr = curr->pright;
        }
    }
    printf("\n");
}

void find_tree_postorder2(dTree* startnode)
{
    std::stack<dTree*> s1, s2;
    s1.push(startnode);
    dTree* pcurr;
    while(s1.size())
    {
        pcurr = s1.top();
        s1.pop();
        s2.push(pcurr);
        if(pcurr->pleft)
            s1.push(pcurr->pleft);
        if(pcurr->pright)
            s1.push(pcurr->pright);
    }
    while(s2.size())
    {
        pcurr = s2.top();
        s2.pop();
        printf("%d, ", pcurr->value);
    }
    printf("\n");

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
        printTree(startnode->pleft);
        printTree(startnode->pright);
        printf("%d, ", startnode->value);
        if(bdelete)
            delete startnode;
    }
}

int main()
{
    int svalue = 0;
    dTree* rootnode = makeTree(svalue, 3);
    find_tree_postorder2(rootnode);
    printTree(rootnode);
    printf("\n");
    return 0;
}
