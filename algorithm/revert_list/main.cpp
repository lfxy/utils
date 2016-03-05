#include <stdio.h>

typedef struct _node
{
    struct _node* pnext;
    int value;
} node;

node* revert(node* head)
{
    if(head == NULL || head->pnext == NULL)
    {
        return head;
    }
    node* pre = head;
    node* cur = head->pnext;
    node* next;

    while(cur->pnext != NULL)
    {
        next = cur->pnext;
        cur->pnext = pre;
        pre = cur;
        cur = next;
    }
    head->pnext = NULL;
    cur->pnext = pre;
    head = cur;
    return head;
}

int main()
{
    node* head = new node;
    head->value = 0;
    node* ptmp = head;
    for(int i = 1; i < 10; ++i)
    {
        ptmp->pnext = new node;
        ptmp = ptmp->pnext;
        ptmp->value = i;
    }
    ptmp->pnext = NULL;

    ptmp = head;
    while(ptmp->pnext != NULL)
    {
        printf("%d,", ptmp->value);
        ptmp=ptmp->pnext;
    }
    printf("%d\n", ptmp->value);
    head = revert(head);
    ptmp = head;
    while(ptmp->pnext != NULL)
    {
        printf("%d,", ptmp->value);
        ptmp=ptmp->pnext;
    }
    printf("%d\n", ptmp->value);
    
    return 0;
}
