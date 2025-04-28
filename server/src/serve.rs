//! Service Implementation

use http_body_util::Full;
use hyper::{
    Method, Request, Response, StatusCode,
    body::{self, Bytes},
    service::Service,
};
use std::{collections::HashMap, fs::File, future::Future, io::Read, pin::Pin};
use url::Url;

/// The service responsible for creating new battles
#[derive(Default, Clone)]
pub struct BattleService;

impl Service<Request<body::Incoming>> for BattleService {
    type Response = Response<Full<Bytes>>;
    type Error = hyper::http::Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self::Response, Self::Error>> + Send>>;

    fn call(&self, req: Request<body::Incoming>) -> Self::Future {
        let mut response = Response::builder();

        let res = async move {
            match (req.method(), req.uri().path()) {
                (&Method::GET, "/") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/index.html").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/dojo") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/dojo.html").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, wasm) if wasm.starts_with("/wasm") => {
                    let mut buf = vec![];
                    let mut w =
                        File::open(format!("frontend{}", wasm)).expect("Failed to find wasm");

                    w.read_to_end(&mut buf).expect("Failed to read to buffer");

                    if wasm.ends_with("js") {
                        response = response.header("content-type", "text/javascript");
                    } else if wasm.ends_with("wasm") {
                        response = response.header("content-type", "application/wasm");
                    }

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/favicon.ico") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/favicon.ico").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, fs) if fs.starts_with("/frontend/") => {
                    let mut buf = vec![];
                    let mut page = File::open(&fs[1..]).expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                _ => unimplemented!(),
            }
        };

        Box::pin(res)
    }
}

/// Creates a map for all query params
pub fn generate_query_map(uri: String) -> HashMap<String, String> {
    let request_url = Url::parse(&format!("https://site.com/{}", uri)).unwrap();

    request_url
        .query_pairs()
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect()
}
