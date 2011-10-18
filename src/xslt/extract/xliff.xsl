<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY xliff "urn:oasis:names:tc:xliff:document:1.2#">
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY dct "http://purl.org/dc/terms/">
    <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="urn:oasis:names:tc:xliff:document:1.2"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
    xmlns="urn:oasis:names:tc:xliff:document:1.2"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    exclude-result-prefixes="#all"
    version="2.0">

    <xsl:param name="autogenerate-fragment-uris" select="'xliff'"/>
    
    <xsl:template match="krextor-genuri:xliff" as="xs:anyURI?">
      <xsl:param name="node"/>
      <xsl:param name="base-uri"/>
      <xsl:apply-templates select="$node" mode="krextor-genuri:xliff"/>
    </xsl:template>

    <xsl:template match="file" mode="krextor-genuri:xliff" as="xs:anyURI?">
      <xsl:sequence select="@original"/>
    </xsl:template>

    <xsl:template match="trans-unit" mode="krextor-genuri:xliff" as="xs:anyURI?">
      <xsl:variable name="original" select="ancestor::file/@original"/>
      <xsl:if test="$original and @id">
        <xsl:sequence select="xs:anyURI(
                              concat(
                              $original,
                              @id))"/>
        
      </xsl:if>
    </xsl:template>

    <xd:doc>Fail to generate a XLIFF compliant URI for all elements for which none is specified, i.e. all elements except <code>file</code> and <code>trans-unit</code></xd:doc>
    <xsl:template match="*" mode="krextor-genuri:xliff" as="xs:anyURI?"/>
    
    <xd:doc>We enforce an empty base URI, so that really just the <code>file/@original</code> URI shows up in the RDF, without any “URI resolution magic”</xd:doc>
    <xsl:template match="/" mode="krextor:main">
      <xsl:apply-imports>
        <xsl:with-param
          name="krextor:base-uri"
          select="xs:anyURI('')"
          as="xs:anyURI"
          tunnel="yes"/>
      </xsl:apply-imports>
    </xsl:template>
    
    <xsl:variable name="krextor:resources">
		<file type="&xliff;File"/>
		<trans-unit type="&xliff;TransUnit"
			related-via-properties="&xliff;hasTransUnit"/>
    </xsl:variable>
	
    <xsl:template match="file|
                         trans-unit"
                  mode="krextor:main">
	<xsl:apply-templates select="." mode="krextor:create-resource"/>
    </xsl:template>
    
    <xsl:variable name="krextor:literal-properties">
      <source property="&xliff;source"/>
    </xsl:variable>
    
    <xsl:template match="source" mode="krextor:main">
      <xsl:apply-templates select="." mode="krextor:add-literal-property"/>
    </xsl:template>
</xsl:stylesheet>