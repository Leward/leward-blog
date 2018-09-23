---
layout:     post
title:      "Notes on Diesel, a Rust ORM"
slug:       diesel-rust-notes
date:       2018-09-23 22:35:00 +0800
categories:
lang:       en
ref:        diesel-rust-notes
excerpt_separator: <!--more-->
---

Lately [I have been playing around](https://twitter.com/pj_Leward/status/1005856316840030208) and enjoyed learning about the Rust programming. Today I spend some time working with [Diesel](http://diesel.rs/), a Rust ORM. 

<!--more-->

## Schema generation

Diesel uses a schema definition (usually called `schema.rs`) to ensure the type-safety of its API. 

When started such a project there are usually two options: 

1. Everything is brand new, there is no existing database 
    -> the dabase can be generated from the data types used in the program
2. Writing a program for an existing database -> you don't necessarily want an exact 1:1 mapping of 
    the DB schema into your code. For many reasons there may be a lot of things your application does not care about in the DB schema

As I have an existing database, I generated my schema using the `diesel print-schema` command. 
The command dumps the DB structure into my `schema.rs` file. 

**Note:** Don't forget to add the generated `schema` module to your `main.rs` using `mod schema;`

## Schema Mapping

The second step is to create the structs corresponding to your shema. 

**schema.rs:**
```rust
table! {
    cover (id) {
        id -> Int8,
        // version -> Int8,
        name -> Varchar,
        url -> Varchar,
    }
}
```

**cover.rs:**
```rust
use diesel::Queryable;

#[derive(Queryable, Clone)]
pub struct Cover {
    pub id: i64,
    pub name: String,
    pub url: String,
}
```

Note that in my schema I commented out the `version` column. Indeed, at this current stage, I don't really care about that field. 

**Note:** If a field is in your `schema.rs`, it should be in your struct as well. If the field is not in the struct, requests will have to specify all the columns every time, which is a bit cumbersome.

**Note:** Make sure the order of the fields in your schema and your struct is the same. Diesel does its mapping using tuples, so the order of the fields matters. 


## The connection to the DB 

If you are working in a simple use case, a single connection to the database may be enough. 
However, if your application is expected to issue multiple requests concurrently, it is recommended to use a pool of connections.

I used the following libraries to help me with the creation of my pool of connections: 
- [lazy_static](https://crates.io/crates/lazy_static): allows to define global constants computed at runetime
- [r2d2](https://crates.io/crates/r2d2): a generic connection pool library
- [r2d2-diesel](https://crates.io/crates/r2d2-diesel): support for diesel connection pool

The snippet below is heavily inspired from a snippet a saw somewhere else, I just can't recall where it was... 

**database.rs**
```rust
use diesel::pg::PgConnection;
use r2d2::{Pool, PooledConnection};
use r2d2_diesel::ConnectionManager;
use std::env;

// Type aliases to simplify a bit the types
type PostgresPool = Pool<ConnectionManager<PgConnection>>;
pub type PostgresPooledConnection = PooledConnection<ConnectionManager<PgConnection>>;

// Using lazy static to have a global reference to my connection pool
// However, I feel that for testing/mocking this won't be great.
lazy_static! {
    static ref POOL: PostgresPool = { init_pool() };
}

fn init_pool() -> PostgresPool {
    // I chose configuration via an environment variable
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let manager = ConnectionManager::<PgConnection>::new(database_url);
    Pool::builder()
        .build(manager)
        .expect("Failed to create pool.") // Unrecoverable failure!
}

/// Get a connection from a static pool of connections
pub fn get_pooled_connection() -> PostgresPooledConnection {
    let pool = POOL.clone();
    let database_connection = pool.get().expect("Failed to get pooled connection"); // Not sure when a panic is triggered here
    database_connection
}
```

## Simple Query

This is how you can then make a query using Diesel: 

```rust
use database::get_pooled_connection;

fn list_covers() -> Vec<Cover> {
    use schema::cover;
    let connection = &*get_pooled_connection();
    cover::table::load(connection).expect("Error loading covers")
}
```

## Joining

Let's have a look at a slightly more complex example involving 2 tables which needs to be joined. 
The snippet below fetches the 5 latest news. 


**schema.rs**
```rust
table! {
    cover (id) {
        id -> Int8,
        name -> Varchar,
        url -> Varchar,
    }
}

table! {
    news (id) {
        id -> Int8,
        content -> Text,
        date -> Nullable<Timestamp>,
        title -> Varchar,
        cover_id -> Int8,
    }
}

joinable!(news -> cover (cover_id)); // Materialize a assiocation and a foreign key

allow_tables_to_appear_in_same_query!(
    cover,
    news,
);
```


**news.rs**
```rust
use chrono::prelude::*;
use diesel::{ExpressionMethods, QueryDsl, Queryable, RunQueryDsl};
use cover::Cover;
use database::get_pooled_connection;

#[derive(Debug, Queryable)]
struct NewsRow {
    id: i64,
    content: String,
    date: Option<NaiveDateTime>,
    title: String,
    cover_id: i64,
}

pub struct News {
    pub id: i64,
    pub content: String,
    pub date: Option<NaiveDateTime>,
    pub title: String,
    pub cover: Cover, // Here I want to have a Cover, not a cover_id
}

impl News {
    fn from(news_row: &NewsRow, cover: &Cover) -> News {
        // Too much cloning? Maybe, I am not sure... 
        News {
            id: news_row.id,
            content: news_row.content.clone(),
            date: news_row.date.clone(),
            title: news_row.title.clone(),
            cover: cover.clone(),
        }
    }
}

fn get_latest_news() -> Vec<News> {
    use schema::cover;
    use schema::news;
    let connection = &*get_pooled_connection();
    news::table
        .inner_join(cover::table)
        .limit(5)
        .order(news::date.desc())
        .load::<(NewsRow, Cover)>(connection) // To this point we get the result as a tuple. 
        .expect("Error loading news") // Another panic waiting to happen!
        .iter()
        .map(|result| News::from(&result.0, &result.1))
        .collect()
}
```

**Note:** When doing a join, diesel returns the result as a tuple. 
This works great if your struct and your schema have the same fields in the same order. 
It it quick trickier to do it otherwise.

In the [diesel documentation](http://diesel.rs/guides/getting-started/) the snippets often indicates `use schema::cover::dsl::*;`, which I don't like very much as it very easily creates conflicts in the names of my variables. It becomes even more confusing whene joinning tables (both are likely to have an `id` column).

In the snippet above I had to use two structs: `NewsRow` and `News`. The reason is that Diesel does not resolve associations in the structs like an ORM like Hibernate (Java) would do. Maybe that's for the better as a lot of the weird stuff with Hibernate happen when handling associations.

I took me quite a while to wrap my head around all of that. I hope this will be useful to someone. I still feel I am just scratching the surface. Once the *I have no Idea what I'm doing* step is over, it is quite enjoyable to use as like many things in rust: if it compile it is likely to work.