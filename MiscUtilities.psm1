$CsCode = @"

using System;
using System.IO;
using System.Runtime.InteropServices;

namespace MiscUtilities
{
    public static class Utility
    {
        [DllImport("Urlmon.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        private static extern int URLDownloadToFile(IntPtr pCaller, string szURL, string szFileName, UInt32 dwReserved, IntPtr lpfnCB); 

        [DllImport("Kernel32.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
        private static extern UInt32 GetLastError();

        public static void DownloadFile(string url, string outPath)
        {  
            if(URLDownloadToFile(IntPtr.Zero, url, Path.GetFullPath(outPath), 0, IntPtr.Zero) != 0)
            {
                throw new Exception("cannot download file, error code: " + GetLastError().ToString());
            }
        }
    }
}

"@

Add-Type -TypeDefinition $CsCode -Language CSharp