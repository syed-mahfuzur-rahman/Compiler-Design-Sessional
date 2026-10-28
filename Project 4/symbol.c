#include <stdio.h>
#include <string.h>

struct symbol
{
    char name[20];
    char type[10];
    int scope;
};



struct symbol table[25];
int count = 0;

int search(char name[], int scope){
    for(int i = 0; i<=count; i++ ){
        if (strcmp(table[i].name, name) == 0 && table[i].scope == scope){
            printf("\n%d\n", i);
            return i;
        }
    }
    return -1;

}


void insert(){

    char name[20];
    char type[10];
    int scope;

    printf("Enter Name: ");
    scanf("%s", name);
    printf("Type: ");
    scanf("%s", type);
    printf("Scope: ");
    scanf("%d", &scope);


    if (search(name, scope) != -1){
        printf("This identifier is already exist\n");
        return;
    }

    strcpy(table[count].name, name);
    strcpy(table[count].type, type);
    table[count].scope = scope;
    count++;

}

void display(){
    if (count == 0){
        printf("Table is empty\n");
    }

    for(int i=0; i<count; i++){
        printf("\n%s\t%s\t%d\n", table[i].name,table[i].type,table[i].scope);
        printf("\n------------------\n");
    }
}

void modify(){

    char name[20];
    int scope;

    printf("Enter Name: ");
    scanf("%s", name);
    printf("Scope: ");
    scanf("%d", &scope);

    int idx = search(name, scope);
    if (idx == -1){
        printf("This identifier doesn't exist\n");
        return;
    }
    int newScope;
    printf("Enter new scope: ");
    scanf("%d", &newScope);

    table[idx].scope = newScope;

}

void delete(){
    char name[20];
    int scope;

    printf("Enter Name: ");
    scanf("%s", name);
    printf("Scope: ");
    scanf("%d", &scope);

    int idx = search(name, scope);
    if (idx == -1){
        printf("This identifier doesn't exist\n");
        return;
    }

    for (int i=0; i<count - 1; i++){
        table[i] = table[i+1];
    }
    count--;

    printf("\nDeleted successfully\n");

}

int main()
{
    int choice;

    do
    {
        printf("1. Insert\n");
        printf("2. Search\n");
        printf("3. Modify\n");
        printf("4. Delete\n");
        printf("5. Display\n");
        printf("6. Exit\n");
        printf("Enter your value: ");
        scanf("%d", &choice);
        switch (choice)
        {
        case 1:
            insert();
            break;

        case 2:
            char name[20];
            int scope;

            printf("Enter Name: ");
            scanf("%s", name);
            printf("Scope: ");
            scanf("%d", &scope);
            search(name, scope);
            break;

        case 3:

            modify();
            break;

        case 4:
            printf("case 3\n");
            delete();
            break;

        case 5:
            printf("case 5\n");
            display();
            break;

        case 6:
            printf("Exiting...\n");
            break;

        default:
            printf("Invalid Choice.\n");
            break;
        };
    } while (choice != 6);
}