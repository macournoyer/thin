#ifndef ext_help_h
#define ext_help_h

#define RAISE_NOT_NULL(T) if(T == NULL) rb_raise(rb_eArgError, "NULL found for " # T " when shouldn't be.");
#define DATA_GET(from,type,name,data_type) TypedData_Get_Struct(from,type,data_type,name); RAISE_NOT_NULL(name);
#define REQUIRE_TYPE(V, T) if(TYPE(V) != T) rb_raise(rb_eTypeError, "Wrong argument type for " # V " required " # T);

#ifdef DEBUG
#define TRACE()  fprintf(stderr, "> %s:%d:%s\n", __FILE__, __LINE__, __FUNCTION__)
#else
#define TRACE() 
#endif

#endif
