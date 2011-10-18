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

    <xsl:param name="autogenerate-fragment-uris" select="'pseudo-xpath'"/>
	
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