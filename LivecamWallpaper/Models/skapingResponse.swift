struct Medias: Decodable {
    let id: String
    let date: String
    let src: String
    let urls: Urls
}

struct Urls: Decodable {
    let thumb: String
    let mini: String
    let small: String
    let large: String
    let hd: String
}

struct SkapingResponse: Decodable {
    let medias: [Medias]
}
