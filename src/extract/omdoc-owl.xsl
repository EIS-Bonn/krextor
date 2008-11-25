<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Jacobs University Bremen
    *
    *   Krextor is free software; you can redistribute it and/or
    * 	modify it under the terms of the GNU Lesser General Public
    * 	License as published by the Free Software Foundation; either
    * 	version 2 of the License, or (at your option) any later version.
    *
    * 	This program is distributed in the hope that it will be useful,
    * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
    * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * 	Lesser General Public License for more details.
    *
    * 	You should have received a copy of the GNU Lesser General Public
    * 	License along with this library; if not, write to the
    * 	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    * 	Boston, MA 02111-1307, USA.
    * 
-->

<!DOCTYPE xsl:stylesheet [
    <!ENTITY owl "http://www.w3.org/2002/07/owl#">
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY omdoc "http://omdoc.org/ns">
]>

<!--
	This stylesheet extracts OWL and RDFS ontologies from OMDoc documents.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://omdoc.org/ns"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns="http://omdoc.org/ns"
    version="2.0">

    <xsl:import href="util/rdfa.xsl"/>

    <xsl:strip-space elements="*"/>
    
    <xsl:template match="symbol">
	<xsl:param name="krextor:sem-web-base" tunnel="yes"/>
	<xsl:call-template name="krextor:create-resource"/>
    </xsl:template>

    <xsl:template match="symbol/type[@system='owl'][om:OMOBJ/om:OMS]">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&rdf;type'"/>
	    <xsl:with-param name="object" select="concat('NS-URL-OF-', om:OMOBJ/om:OMS/@cd, '/', om:OMOBJ/om:OMS/@name)"/>
	</xsl:call-template>
    </xsl:template>

    <!-- Try to find the ontology namespace (special metadata field
         omdoc:semwebbase) -->
    <xsl:template match="theory">
	<xsl:variable name="sem-web-base">
	    <xsl:variable name="link">
		<xsl:value-of select="metadata/link[krextor:curie-to-uri(., @rel) eq '&omdoc;semWebBase']"/>
	    </xsl:variable>
	    <xsl:message select="boolean(trace($link, 'foo'))"/>
	    <xsl:value-of select="if ($link) then $link/@href else ()"/>
	</xsl:variable>
	<xsl:choose>
	    <xsl:when test="$sem-web-base">
		<xsl:apply-templates>
		    <xsl:with-param name="krextor:sem-web-base" select="$sem-web-base" tunnel="yes"/>
		</xsl:apply-templates>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:apply-templates/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:template>
</xsl:stylesheet>
