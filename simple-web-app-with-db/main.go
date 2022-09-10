package main

import (
   "fmt"
   "log"
   "net/http"
   "context"
   "github.com/go-redis/redis/v9"
)

var dbClient *redis.Client
var key = "pv"
var ctx = context.Background()

func init() {
   dbClient = redis.NewClient(&redis.Options{
      Addr : "db:6379",
   })
}
func main() {
   http.HandleFunc("/", handler)
   log.Fatal(http.ListenAndServe("0.0.0.0:30009", nil))
}

func handler(w http.ResponseWriter, r *http.Request) {
   log.Printf("Ping from %s", r.RemoteAddr)
   countPageView, err := dbClient.Incr(ctx, key).Result()
   if err != nil {
      panic(err)
   }
   fmt.Fprintf(w, "Hello you are visitar #%d !", countPageView)
}
