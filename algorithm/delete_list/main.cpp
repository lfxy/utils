#include <stdio.h>

typedef struct _node
{
    struct _node* pnext;
    int value;
} node;

node* make_list()
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
    return head;
}

node* delete_list(node* head, node* toBeDeleted)
{
    if(head == NULL || toBeDeleted == NULL)
    {
        return head;
    }
    if(toBeDeleted->pnext != NULL)
    {
        node* tmp = toBeDeleted->pnext;
        toBeDeleted->pnext = tmp->pnext;
        toBeDeleted->value = tmp->value;
        delete tmp;
        tmp = NULL;
    }
    else if(head == toBeDeleted)
    {
        delete toBeDeleted;
        head = NULL;
        toBeDeleted = NULL;
    }
    else
    {
        node* tmp = head;
        while(tmp->pnext != toBeDeleted)
        {
            tmp = tmp->pnext;
        }
        tmp->pnext = NULL;
        delete toBeDeleted;
        toBeDeleted = NULL;
    }
    return head;
}

int main()
{
    node* head = make_list();
    node* pfordelete = NULL;
    node* ptmp = head;
    printf("----------before start-----------\n");
    while(ptmp->pnext != NULL)
    {
        printf("%d,", ptmp->value);
        if(ptmp->value == 5)
            pfordelete = ptmp;
        ptmp=ptmp->pnext;
    }
    printf("%d\n", ptmp->value);
    printf("----------before end-----------\n");
    head = delete_list(head, pfordelete);
    ptmp = head;
    printf("----------after start-----------\n");
    while(ptmp->pnext != NULL)
    {
        printf("%d,", ptmp->value);
        ptmp=ptmp->pnext;
    }
    printf("%d\n", ptmp->value);
    printf("----------after end-----------\n");
    return 0;
}
