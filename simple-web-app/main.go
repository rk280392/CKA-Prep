package main

import (
   "fmt"
   "log"
   "net/http"
)

var countPageView int64

func main() {
   http.HandleFunc("/", handler)
   log.Fatal(http.ListenAndServe("0.0.0.0:30009", nil))
}

func handler(w http.ResponseWriter, r *http.Request) {
   log.Printf("Ping from %s", r.RemoteAddr)
   countPageView++
   fmt.Fprintf(w, "Hello you are visitar #%d !", countPageView)
}
