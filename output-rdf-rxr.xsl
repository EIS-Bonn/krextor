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

<!--
This stylesheet provides low-level triple-creation functions and templates for
an RDF/RXR extraction from XML languages.

So far the extraction only works on the toplevel of a document, a restriction influenced by the setting of a semantic wiki, namely SWiM.

TODO but sub-pagelevel resources should also be supported, just with the GUI support being a bit restricted. I.e. that you can jump to them (the whole page would be loaded and the respective fragment shown), but you would e.g. not see relationships between fragments in the "references" portlet.

Specification of RXR:
http://www.idealliance.org/papers/dx_xmle04/papers/03-08-03/03-08-03.html
http://ilrt.org/discovery/2004/03/rxr/
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:rxr="http://ilrt.org/discovery/2004/03/rxr/"
    xmlns:krextor="http://kwarc.info/projects/krextor/"
    exclude-result-prefixes="krextor"
    version="2.0">
    <xsl:import href="generic-templates.xsl"/>

    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

    <xsl:function name="krextor:triple-uri">
	<xsl:param name="subject"/>
	<xsl:param name="predicate"/>
	<xsl:param name="object"/>
	<xsl:variable name="rxr-object">
	    <rxr:object uri="{$object}"/>
	</xsl:variable>
	<xsl:sequence select="krextor:triple($subject, $predicate, $rxr-object)"/>
    </xsl:function>
    
    <xsl:function name="krextor:triple-lit">
	<xsl:param name="subject"/>
	<xsl:param name="predicate"/>
	<xsl:param name="object"/>
	<xsl:variable name="rxr-object">
	    <rxr:object>
		<xsl:value-of select="$object"/>
	    </rxr:object>
	</xsl:variable>
	<xsl:sequence select="krextor:triple($subject, $predicate, $rxr-object)"/>
    </xsl:function>

    <xsl:function name="krextor:triple">
	<xsl:param name="subject"/>
	<xsl:param name="predicate"/>
	<xsl:param name="object"/>
	<rxr:triple>
	    <rxr:subject uri="{$subject}"/>
	    <rxr:predicate uri="{$predicate}"/>
	    <xsl:copy-of select="$object"/>
	</rxr:triple>
    </xsl:function>

    <xsl:template match="/">
	<rxr:graph>
	    <xsl:apply-imports/>
	</rxr:graph>
    </xsl:template>
</xsl:stylesheet>
