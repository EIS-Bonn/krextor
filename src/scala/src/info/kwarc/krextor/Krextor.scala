package info.kwarc.krextor

import scala.xml._

object Krextor {
  def outputTriple(subjectURI : String, predicateURI : String, objectURI : Any) : Unit = {
    printf("<%s> <%s> <%s> .\n", subjectURI, predicateURI, objectURI)
  }

  def createResource(n : Node, t : Any) : Unit = {
     outputTriple(n.label, "rdf:type", t.toString)
  }
  
  def process(n : Node) : Unit = {
    n match {
      case t @ <omtext/> =>
        createResource(n, if (!(t \ "@type").isEmpty) t \ "@type" else "other")
      case _ =>
        ;
    }
  }
  
  def main(args : Array[String]) : Unit = {
    val doc =
      <omtext/>;
      // <omtext type="definition"/>;
    
    process(doc);
  }
}
