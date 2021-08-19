import Defaults
import SwiftUI

final class SkapingController {
    static let shared = SkapingController()

    func fetchImage(livecamURL: URL, completion: @escaping (String?) -> Void) {
        URLSession.shared.dataTask(with: livecamURL) { data, response, error in
            if let error = error {
                completion(error.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion("Livecam not found")
                return
            }
            guard
                let mimeType = httpResponse.mimeType, mimeType == "text/html",
                let data = data,
                let str = String(data: data, encoding: .utf8)
            else {
                completion("Livecam not found")
                return
            }

            let regex = try? NSRegularExpression(pattern: "SkapingAPI.setConfig\\('http://api.skaping.com/', '(.*)'\\)")
            let match =
                regex?.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf8.count - 100))
            if match == nil {
                completion("Livecam not found")
                return
            }
            let range = match!.range(at: 1)

            guard let keyRange = Range(range, in: str) else {
                completion("Livecam not found")
                return
            }

            let apiKey = str[keyRange]

            self.getTitle(page: str)

            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "y-MM-dd HH:mm"
            let formatedDate = formatter.string(from: now)

            let imagesURL = URL(string: "https://api.skaping.com//media/search")!
            var request = URLRequest(url: imagesURL)
            request.httpMethod = "POST"
            let body = "types=image&center=" + formatedDate + "&count=10&api_key=" + apiKey
            request.httpBody = body.data(using: String.Encoding.utf8)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion("Can't decode response, check URL")
                    return
                }

                guard
                    let response = try? JSONDecoder().decode(SkapingResponse.self, from: data!)
                else {
                    completion("Can't decode response, check URL")
                    return
                }

                if response.medias.count == 0 {
                    completion("No media for this livecam")
                    return
                }

                DispatchQueue.main.async {
                    let image = response.medias[response.medias.count - 1].src
                    let secureimage = image.replacingOccurrences(of: "http", with: "https")
                    let url = URL(string: secureimage)!
                    AppDelegate.shared.downloadImage(url: url)
                }
            }.resume()
        }.resume()
    }

    func getTitle(page: String) {
        let regex = try? NSRegularExpression(pattern: "<title>(.*)<\\/title>")
        let match =
            regex?.firstMatch(in: page, options: [], range: NSRange(location: 0, length: page.utf8.count - 100))!
        let range = match!.range(at: 1)
        if match != nil {
            if let keyRange = Range(range, in: page) {
                Defaults[.livecamTitle] = String(page[keyRange])
            }
        }
    }
}
