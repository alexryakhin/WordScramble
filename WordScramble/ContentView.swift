//
//  ContentView.swift
//  WordScramble
//
//  Created by Alexander Bonney on 4/30/21.
//

import SwiftUI

struct ContentView: View {
    
    @State private var usedWords = Array<String>()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var score = 0
    
    //some code to make showing error alerts easier
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        
        NavigationView {
            VStack {
                TextField("Enter your word", text: $newWord, onCommit: addNewWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                
                List(usedWords, id: \.self) { word in
                    Image(systemName: "\(word.count).circle")
                    Text(word)
                }
                
                Text("Score: \(score)")
            }
            
            .navigationBarTitle(rootWord)
            .onAppear(perform: newGame)
            .navigationBarItems(trailing: Button(action: {
                usedWords.removeAll()
                newGame()
            }, label: {
                Text("New game")
            }))
            .alert(isPresented: $showingError) {
                Alert(title: Text(errorTitle), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                    
            }
//            .padding()
//            .listStyle(GroupedListStyle())
        }
    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't add duplicate words with case differences
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // exit if the remaining string is empty
        guard answer.count > 0 else {
                return
            }
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original. You lose 2 score points.")
            score -= 2
            return
        }

        guard isPossible(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know! You lose 3 score points.")
            score -= 3
            return
        }

        guard isReal(word: answer) else {
            wordError(title: "Word not possible", message: "That word is shorter than 3 letters, or it doesn't exist. You lose 5 score points.")
            score -= 5
            return
        }
        score += 10
        usedWords.insert(answer, at: 0)
        newWord = ""
    }
    
    func newGame() {
        // 1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // we found the file in our bundle! 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")
                // 4. Pick one random word, or use "silkworm" as a sensible default
                
                rootWord = allWords.randomElement() ?? "silkworm"
                // If we are here everything has worked, so we can exit
                return
            }
        }
        
        // If were are *here* then there was a problem – trigger a crash and report the error
            fatalError("Could not load start.txt from bundle.")
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        //if we create a variable copy of the root word, we can then loop over each letter of the user’s input word to see if that letter exists in our copy. If it does, we remove it from the copy (so it can’t be used twice), then continue. If we make it to the end of the user’s word successfully then the word is good, otherwise there’s a mistake and we return false.
        
        var tempWord = rootWord
        
        for letter in word {
                if let position = tempWord.firstIndex(of: letter) {
                    tempWord.remove(at: position)
                } else {
                    return false
                }
            }
        return true
    }
    
    func isReal(word: String) -> Bool {
        // The final method is harder, because we need to use UITextChecker from UIKit. In order to bridge Swift strings to Objective-C strings safely, we need to create an instance of NSRange using the UTF-16 count of our Swift string. This isn’t nice, I know, but I’m afraid it’s unavoidable until Apple cleans up these APIs.
        
        //So, our last method will make an instance of UITextChecker, which is responsible for scanning strings for misspelled words. We’ll then create an NSRange to scan the entire length of our string, then call rangeOfMisspelledWord() on our text checker so that it looks for wrong words. When that finishes we’ll get back another NSRange telling us where the misspelled word was found, but if the word was OK the location for that range will be the special value NSNotFound.
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        
        if range.length > 2 && newWord != rootWord {
            let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
            return misspelledRange.location == NSNotFound
        } else {
            return false
        }
        
    }
    
    func wordError(title: String, message: String) {
        //we can add a method that sets the title and message based on the parameters it receives, then flips the showingError Boolean to true
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
