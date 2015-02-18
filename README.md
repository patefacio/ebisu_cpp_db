# Ebisu Cpp Db

A package that generates C++ code supporting various types of access to specific schema of a relational database. This is not about the layer that interacts directly with the database. Rather, it is the often boilerplate code that sits on top of that, providing access to tables and queries in fairly standard ways.

# Purpose

Ideally, C++ *CRUD* support can be provided by pointing some code generation utilities at a database and having it spit out all the code required. That is the goal of this project. The initial focus will be linux and MySql, however the C++ is generated and fairly standard. The interface to the database is achieved through OTL but written in such a way that other libraries could be supported (e.g. poco or qt).

# Examples

For sample code that is using these code generation utilities see the generated code in [fcs project against the *code_metrics* schema](https://github.com/patefacio/fcs/tree/master/cpp/fcs/orm/code_metrics)



