package info.kwarc.krextor

import scala.xml._

object Krextor {
  def outputTriple(subjectURI : String, predicateURI : String, objectURI : Any) : Unit = {
    printf("<%s> <%s> <%s> .\n", subjectURI, predicateURI, objectURI)
  }

  def createResource(n : Node, t : Any, baseURI : String) : Unit = {
    
    
    val newBaseURI = baseURI + "/" + n.label + "-" + n.attribute("http://www.w3.org/XML/1998/namespace", "id").get
    
     outputTriple(newBaseURI, "rdf:type", t.toString)
     
     for (c <- n.attributes)
       processAttribute(c.key, c.value.toString, newBaseURI)
     
     for (c <- n.child)
       process(c, newBaseURI)
  }
  
  def addProperty(p : String, o : String, baseURI : String) : Unit = {
     outputTriple(baseURI, p, o)
  }
  
  def processAttribute(k : String, v : String, baseURI : String) : Unit = {
    k match {
      case "for" => addProperty("defines", v, baseURI)
      case _ => ;
    }
  }
  
  def process(n : Node, baseURI : String) : Unit = {
    n match {
      case t @ <omtext>{ _* }</omtext> =>
        createResource(n, t \ "@type", baseURI)
      case _ => ;
    }
  }
  
  def main(args : Array[String]) : Unit = {
    val doc =
      <omtext xml:id="foo" type="definition" for="#foo">
        <omtext xml:id="bar" type="bla" for="#xyzzy"/>
      </omtext>
    
    process(doc, "");
  }
}
