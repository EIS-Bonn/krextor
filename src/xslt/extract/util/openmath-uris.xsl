<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008–2012
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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns:cdg="http://www.openmath.org/OpenMathCDG"
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">
    <xd:doc type="stylesheet">A collection of utility functions for <a href="http://www.openmath.org">OpenMath</a> symbol URIs
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008–2012</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>
    
    <xsl:function name="om:cdbase-or-default">
	<xsl:param name="cdbase"/>
        <xsl:sequence select="om:cdbase-or-default($cdbase, '')"/>
    </xsl:function>

    <xsl:function name="om:cdbase-or-default" as="xs:anyURI?">
	<xsl:param name="cdbase-or-cdgroup"/>
	<xsl:param name="cd"/>
	<xsl:sequence select="xs:anyURI(
                              if ($cdbase-or-cdgroup) then
                                if ($cd and $cdbase-or-cdgroup instance of document-node()) then
                                  (: We do not currently support changing the value of the CD in the course of this lookup.  Instead we assume that the last path component from the CDURL is equal to the original CD name passed as $cd, and if to, we strip it. :)
                                  substring-before(
                                    $cdbase-or-cdgroup/cdg:CDGroup/cdg:CDGroupMember[cdg:CDName eq $cd]/cdg:CDURL,
                                    concat('/', $cd))
                                else $cdbase-or-cdgroup
                              else 'http://www.openmath.org/cd')"/>
    </xsl:function>

    <xd:doc>Canonical URI for a symbol (OpenMath 2.0 standard, section 2.3)</xd:doc>
    <xsl:function name="om:symbol-uri" as="xs:anyURI?">
        <!-- if a document node: assumed to be a document node of a CDGroup document
             otherwise assumed to be a string denoting the cdbase -->
	<xsl:param name="cdbase-or-cdgroup"/>
	<xsl:param name="cd"/>
	<xsl:param name="name"/>

        <xsl:variable name="cdbase" select="om:cdbase-or-default($cdbase-or-cdgroup, $cd)"/>
        <!-- If the cdbase is not well-defined (which means in practice: if the cdgroup mechanism is used and lookup fails), the URI of the symbol is not defined -->
	<xsl:sequence select="if ($cdbase) then xs:anyURI(concat($cdbase, '/', $cd, '#', $name)) else ()"/>
    </xsl:function>
</xsl:stylesheet>

<!--
Local Variables:
mode: nxml
nxml-child-indent: 4
End:
-->

