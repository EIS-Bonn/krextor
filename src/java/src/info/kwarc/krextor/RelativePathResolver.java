/*  Copyright (C) 2008
 *  Christoph Lange
 *  KWARC, Jacobs University Bremen
 *  http://kwarc.info/projects/krextor/
 *
 *   Krextor is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2 of the License, or (at your option) any later version.
 *   
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *   
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the
 *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 *   Boston, MA 02111-1307, USA.
 */
package info.kwarc.krextor;

import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamSource;

import org.apache.commons.vfs.FileSystemException;
import org.apache.commons.vfs.FileSystemManager;
import org.apache.commons.vfs.VFS;

/**
 * This is a custom URI resolver for relative paths. 
 * We're rolling our own because Saxon's standard resolver, which uses
 * new URI(base).resolve(href) doesn't work with jar:file:... URIs.
 * 
 * Its central method, <code>resolvePath</code>, can also be used for other purposes.
 * 
 * @author Christoph Lange
 * 
 * @see java.net.URI#resolve(java.net.URI)
 */
public class RelativePathResolver implements URIResolver {
	private static FileSystemManager fsm;
	static {
		try {
			fsm = VFS.getManager();
		}
		catch (FileSystemException exc) {
			// This should never happen
			throw new ExceptionInInitializerError("could not create a VFS file system manager");
		}
	}
	
	/**
	 * Resolves a relative path against a base path, regardless of whether any one of them exists.
	 * 
	 * @param relative the relative path to resolve
	 * @param base ... against this base
	 * @return an absolute path for <code>relative</code>
	 * @throws FileSystemException
	 */
	public static String resolvePath(String relative, String base) throws FileSystemException {
		return fsm.resolveName(fsm.resolveURI(base).getParent(), relative).getURI();
	}
	
	/** 
	 * Resolves the relative URL <code>href</code> against <code>base</code> using
	 * <code>resolvePath</code> 
	 * 
	 * @see javax.xml.transform.URIResolver#resolve(java.lang.String, java.lang.String)
	 * @see #resolvePath(String, String)
	 */
	public Source resolve(String href, String base) throws TransformerException {
		// log.info("relative resolving of " + href + " against " + base);
		String abs;
		
		if (!href.isEmpty()) {
			try {
				abs = resolvePath(href, base);
			}
			catch (FileSystemException exc) {
				throw new TransformerException("error resolving " + href + " against " + base, exc);
			}
		} else {
			abs = base;
		}
		
		return new StreamSource(abs);
	}

}
