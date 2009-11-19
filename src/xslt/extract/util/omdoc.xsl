<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  KWARC, Jacobs University Bremen
    *  http://kwarc.info/projects/krextor/
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

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://omdoc.org/ns"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:cc="http://creativecommons.org/ns#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:f="http://fxsl.sf.net/"
    version="2.0">

    <import href="rdfa.xsl"/>

    <xd:doc type="stylesheet">A collection of utility functions for <a href="http://www.omdoc.org">OMDoc</a> support
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>
		
    <xd:doc>Support for legacy hard-coded DC and CC metadata</xd:doc>
    <template match="metadata/dc:*|metadata/cc:*" mode="krextor:main">
	    <call-template name="krextor:add-literal-property">
		    <with-param name="property" select="concat(namespace-uri(), local-name())"/>
	    </call-template>
    </template>

    <template match="meta" mode="krextor:main">
	<apply-templates select="@property"/>
    </template>

    <template match="link" mode="krextor:main">
	<apply-templates select="@rel|@rev"/>
    </template>

    <template match="resource" mode="krextor:main">
	<variable name="type" select="krextor:curies-to-uris(., @typeof)"/>
	<variable name="blank-node-id" select="if (@about) then krextor:safe-curie-to-bnode-id(@about) else ()"/>
	<call-template name="krextor:create-resource">
	    <with-param name="this-blank-node-id" select="$blank-node-id"/>
	    <with-param name="blank-node" select="true()"/>
	    <with-param name="type" select="$type"/>
            <with-param name="process-next" select="*"/>
        </call-template>
    </template>
</stylesheet>
