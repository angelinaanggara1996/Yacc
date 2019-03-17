%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

/*Extern variables that communicate with lex*/
#define RED   "\033[0;32;31m"
#define WHITE "\x1B[37m"

int k=0;
int legit=1;
int tip=0;

extern int yylineno;
extern int yylex();

void yyerror(char *);

struct word {
      char *id;
      char *type;
	  int val;
      struct word *next;
};
struct word *word_list; /* first element in word list */

void create_symbol();		
void insert_symbol(char* word, char* type, int data);	
void symbol_assign(char* word, int data);	
int lookup_symbol(char* word);					
void dump_symbol(struct word* wp, int k);					
int symnum;											/*The number of the symbol*/

%}

%token SEM PRINT WHILE INT DOUBLE LB RB
%token STRING ADD SUB MUL DIV
%token ASSIGN NUMBER FLOATNUM ID 

%union {
	float float_num;
	int integer_num;
	char str[50];
}

%type <float_num> FLOATNUM 
%type <integer_num> NUMBER exp term factor group
%type <str> STRING ID INT DOUBLE Type While

%%
line:
	| line stmt
	;
stmt: Decl SEM {}
	| Print SEM {}
	| Assign SEM {}
	| While SEM {}
	| exp SEM {}
	;
Decl: Type ID 
	  {
		if(k==0) create_symbol();
		if(lookup_symbol($2)!=-1) 
		{
			printf(RED"<ERROR>");
			printf(WHITE" Re-declaration for variable %s ------ on %d line\n",$2,yylineno);
			
		}
		else{
			insert_symbol($2,$1,0);
			printf("Insert Symbol : %s\n",$2);
			k=k+1;
		}
		
	  }
	| Type ID ASSIGN exp 
	  { 
		 if(k==0) create_symbol();
		 if(lookup_symbol($2)!=-1)
		 {
			printf(RED"<ERROR>");
			printf(WHITE" Re-declaration for variable %s ------ on %d line\n",$2,yylineno);
		 }
		 else{
			insert_symbol($2,$1,$4);
			printf("Insert Symbol : %s\n",$2);
			k=k+1;	
		 }
	  }
	  ;
Type: INT		{strcpy($$,$1); tip=0;}
	| DOUBLE	{strcpy($$,$1); tip=1;}
	;
Assign: ID  ASSIGN exp 
		{
			if(legit==1)
			{
				printf("ASSIGN \n");
				if(lookup_symbol($1)==-1){
					printf(RED"<ERROR>");
					printf(WHITE" cannot find the variable %s ----on %d line \n",$1,yylineno);
				}
				symbol_assign($1,$3);
			}
			else { 
				printf("ASSIGN \n");
				if(lookup_symbol($1)==-1)
				{
					printf(RED"<ERROR>");
					printf(WHITE" cannot find the variable %s ----on %d line \n",$1,yylineno);
				}	
				else 
					legit=1 ;								
			}
		}
		;
While: WHILE group {
						if(legit==1)
								printf("While : %d\n",$2); 
						else
								legit=1;
					}
exp
	: term						{ $$ = $1; }
	| exp ADD term		{ $$ = $1 + $3; printf("Add   \n");}
	| exp SUB term		{ $$ = $1 - $3; printf("Sub   \n");}
	;
term
	: factor					{ $$ = $1; }
	| term MUL factor			{
									if(legit==1){
										$$=$1*$3;
										printf("Mul \n");
									}
									else{
										printf("Mul \n");
									}
								}
	| term DIV factor			{
									if(legit==1){ 
										if($3==0)
										{
											printf(RED"<ERROR>");
											printf(WHITE" The divisor can not be 0------on %d line\n",yylineno);
										}
										else{
											$$ = $1 / $3;
											printf("Div  \n"); 
											
										}
									}
									else{printf("Div \n");} 
								}
	;
factor
	: NUMBER			{ $$ = $1; }
	| FLOATNUM			{ $$ = $1; }
	| group				{ $$ = $1; }
	| ID				{  
							if(lookup_symbol($1)==-1){
								printf(RED"<ERROR>");
								printf(WHITE" cannot find the variable %s ----on %d line \n",$1,yylineno);
								legit=0;
							}
							 else{
								$$= lookup_symbol($1);
							}
						}
	;
Print: PRINT group	{	if(legit==1)
								printf("Print : %d\n",$2); 
						else
								legit=1;
					} 
	| PRINT LB STRING RB   {printf("Print : %s\n",$3);} 
	;
group: LB exp RB		{ $$ = $2; }
	| SUB factor		{ $$ = -$2; }
	;
%%

int main(int argc, char** argv)
{
    //yylineno = 1;
    symnum = 0;
    yyparse();

	printf("\n\nTotal Lines: %d \n",yylineno);
	dump_symbol(word_list,k);
    return 0;
}

void yyerror(char *s) {
    printf(RED"<ERROR>");
    printf(WHITE"%s ------ on %d line \n", s , yylineno);
}


extern void *malloc() ;

/*symbol create function*/
void create_symbol() {
	printf("Create a symbol table\n\n");
}

/*symbol insert function*/
void insert_symbol(char* word, char* type, int data) {
	struct word *wp;
	if(lookup_symbol(word) !=-1) {
        	printf(" %s has been already declared \n", word);
		//return -1;
    }
	else{
      		/*insert word*/
      		wp = (struct word *) malloc(sizeof(struct word));
      		wp->next = word_list;
      		/*copy the word itself*/
      		wp->id = (char *) malloc(strlen(word)+1);
      		strcpy(wp->id, word);
			wp->type = (char *) malloc(strlen(type)+1);
      		strcpy(wp->type, type);
			/*wp->val = (char *) malloc(strlen(val)+1);
      		strcpy(wp->val, val);
			*/
			 wp->val = data;
      		word_list = wp;
		//return 1;
	}
}


/*symbol value lookup and check exist function*/
int lookup_symbol(char* word){
	struct word *wp = word_list;
	/*searching the symbol table*/
    	for(; wp; wp = wp->next) {
			if(strcmp(wp->id, word) == 0)
			{
          		return wp->val;
			}
    	}
      	return -1;       /* not found */
}

/*symbol value assign function*/
void symbol_assign(char* id, int data) {
	struct word *wp = word_list;
	for(; wp; wp = wp->next) {
		if(strcmp(wp->id,id) == 0){
          		wp->val = data;
    	}

	}
}

/*symbol dump function*/
void dump_symbol(struct word* wp, int k){
	if (wp == NULL)
       		return;
	dump_symbol(wp->next,--k);

	if(k==0){
		printf("\nThe symbol table :\n");
		printf("\nIndex \tID \t\tType \tData\n");
	}		
    printf("%d \t%s \t\t%s \t%d\n", ++k,wp->id, wp->type,wp->val);
}