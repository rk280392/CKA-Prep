package main

import (
   "fmt"
   "log"
   "net/http"
)

func main() {
   http.HandleFunc("/", handler)
   log.Fatal(http.ListenAndServe("0.0.0.0:30008", nil))
}

func handler(w http.ResponseWriter, r *http.Request) {
   log.Printf("Ping from %s", r.RemoteAddr)
   fmt.Fprintln(w, "Learning kubernetes!")
}
