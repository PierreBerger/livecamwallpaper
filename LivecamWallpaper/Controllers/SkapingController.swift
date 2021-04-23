import SwiftUI
import Defaults

final class SkapingController {
    static let shared = SkapingController()
    
    func fetchImage(livecamURL: URL) {
        URLSession.shared.dataTask(with: livecamURL) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    AppDelegate.shared.setError(message: "Error: \(error.localizedDescription)")
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("serveur error")
                return
            }
            print(httpResponse)
            if let mimeType = httpResponse.mimeType, mimeType == "text/html",
               let data = data,
               let str = String(data: data, encoding: .utf8) {
                
                DispatchQueue.main.async {
                    let regex = try! NSRegularExpression(pattern: "SkapingAPI.setConfig\\('http://api.skaping.com/', '(.*)'\\)")
                    let match = regex.firstMatch(in: str, options: [], range: NSRange(location: 0, length: str.utf8.count-100))
                    if match == nil {
                        AppDelegate.shared.setError(message: "Error: Livecam not found")
                        return
                    }
                    let range = match!.range(at:1)
                    if let keyRange = Range(range, in: str) {
                        let apiKey = str[keyRange]
                        print(apiKey)
                        
                        self.getTitle(page: str)
                        
                        let now = Date()
                        let formatter = DateFormatter()
                        formatter.dateFormat = "y-MM-d HH:mm"
                        let formatedDate = formatter.string(from: now)
                        
                        let imagesURL = URL(string: "https://api.skaping.com//media/search")!
                        var request = URLRequest(url: imagesURL)
                        request.httpMethod = "POST"
                        let body = "types=image&center=" + formatedDate + "&count=10&api_key=" + apiKey
                        request.httpBody = body.data(using: String.Encoding.utf8);
                        
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if let error = error {
                                print("error \(error)")
                                return
                            }
                            guard let httpResponse = response as? HTTPURLResponse,
                                  (200...299).contains(httpResponse.statusCode) else {
                                print("error \(response)")
                                return
                            }
                       
                               let data = data!
                               let response = try! JSONDecoder().decode(SkapingResponse.self, from: data)
                            
                            DispatchQueue.main.async {
                                let image = response.medias[response.medias.count-1].src
                                let secureimage = image.replacingOccurrences(of: "http", with: "https")
                                let url = URL(string: secureimage)!
                                AppDelegate.shared.downloadImage(url: url)
                            }
                            
                        }.resume()
        
                    }
                    
                }
            }
        }.resume()
    }
    
    func getTitle(page: String) {
        let regex = try! NSRegularExpression(pattern: "<title>(.*)<\\/title>")
        let match = regex.firstMatch(in: page, options: [], range: NSRange(location: 0, length: page.utf8.count-100))!
        let range = match.range(at:1)
        if let keyRange = Range(range, in: page) {
            Defaults[.livecamTitle] = String(page[keyRange])
        }
        
    }
}
