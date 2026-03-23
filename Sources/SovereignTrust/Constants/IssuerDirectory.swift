import Foundation
enum IssuerDirectory {
    static let all: [Issuer] = [
        Issuer(id:"iitb",      did:"did:sov:IIT-Bombay-0xA1B2C3",  name:"Indian Institute of Technology Bombay", shortName:"IIT Bombay",  logoEmoji:"🎓", category:"university",  trustState:.verified, isVerified:true,  country:"IN"),
        Issuer(id:"uidai",     did:"did:sov:UIDAI-GOV-0xD4E5F6",   name:"Unique Identification Authority of India", shortName:"UIDAI",   logoEmoji:"🏛️", category:"government",  trustState:.verified, isVerified:true,  country:"IN"),
        Issuer(id:"aws",       did:"did:sov:Amazon-AWS-0xG7H8I9",   name:"Amazon Web Services",               shortName:"AWS",         logoEmoji:"☁️", category:"corporate",   trustState:.trusted,  isVerified:true,  country:"US"),
        Issuer(id:"mit",       did:"did:sov:MIT-0xP1Q2R3",          name:"Massachusetts Institute of Technology", shortName:"MIT",      logoEmoji:"🏫", category:"university",  trustState:.verified, isVerified:true,  country:"US"),
        Issuer(id:"sebi",      did:"did:sov:SEBI-GOV-0xS4T5U6",    name:"Securities and Exchange Board of India", shortName:"SEBI",    logoEmoji:"📈", category:"government",  trustState:.trusted,  isVerified:true,  country:"IN"),
        Issuer(id:"acm",       did:"did:sov:ACM-0xJ1K2L3",          name:"Association for Computing Machinery", shortName:"ACM",       logoEmoji:"💻", category:"ngo",         trustState:.trusted,  isVerified:true,  country:"US"),
        Issuer(id:"anthropic", did:"did:sov:Anthropic-0xM4N5O6",    name:"Anthropic",                          shortName:"Anthropic",  logoEmoji:"🤖", category:"corporate",   trustState:.trusted,  isVerified:true,  country:"US"),
        Issuer(id:"rbi",       did:"did:sov:RBI-GOV-0xR1B2I3",      name:"Reserve Bank of India",              shortName:"RBI",        logoEmoji:"🏦", category:"government",  trustState:.verified, isVerified:true,  country:"IN"),
        Issuer(id:"isro",      did:"did:sov:ISRO-GOV-0xI1S2R3",     name:"Indian Space Research Organisation", shortName:"ISRO",       logoEmoji:"🚀", category:"government",  trustState:.verified, isVerified:true,  country:"IN"),
    ]
    static func find(did: String) -> Issuer? { all.first { $0.did == did } }
    static func find(id: String) -> Issuer?  { all.first { $0.id == id  } }
}
