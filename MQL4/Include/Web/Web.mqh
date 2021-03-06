//+------------------------------------------------------------------+
//|                                                          Web.mqh |
//|                                 Copyright 2017, Keisuke Iwabuchi |
//|                                         https://order-button.com |
//+------------------------------------------------------------------+
#property strict


#ifndef _LOAD_MODULE_WEB
#define _LOAD_MODULE_WEB


/**　@var int HTTP_TIMEOUT  Time limt. [millisecond] */
#define HTTP_TIMEOUT 5000


/** import library files */
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
#import

#import "shell32.dll"
   int ShellExecuteW(int, string, string, string, string, int);
#import


/** Parameter structure for HTTP request. */
struct WebParameter
{
   string key;   // key
   string value; // value
};


/** Class for HTTP request. */
class Web
{
   public:
      static WebParameter params[];
      
      static bool request(const string  url,
                          const string  method,
                                char   &data[],
                                string &response);
      static void addParameter(const string key, const string value);
      static void resetPrameter(void);
      static bool get(string url, string &response);
      static bool post(string url, string &response);
      static bool download(string url, string path);
};


/** 
 * @var WebParameter params  An array that 
 *                           holds the parameters of the HTTP request.
 */
WebParameter Web::params[];


/**
 * HTTP request.
 *
 * @param const string url  URL.
 * @param const string method  HTTP method.
 * @param char &data[]  Data array of the HTTP message body.
 * @param string &response  Server response data.
 *
 * @return bool  Returns true if successful, otherwise flase.
 */
static bool Web::request(const string  url,
                         const string  method,
                               char   &data[],
                               string &response)
{
   if(IsTesting()) return(false);
   
   int    status_code;
   string headers;
   char   result[];
   uint   timeout = GetTickCount();
   
   status_code = WebRequest(method, 
                            url, 
                            NULL, 
                            NULL, 
                            HTTP_TIMEOUT, 
                            data, 
                            ArraySize(data), 
                            result, 
                            headers);
   
   if(status_code == -1) {
      if(GetTickCount() > timeout + HTTP_TIMEOUT) {
         Print("WebRequest get timeout");
      }
      else {
         Print(ErrorDescription(GetLastError()));
      }
      return(false);
   }
   
   response = CharArrayToString(result, 0, ArraySize(result), CP_UTF8);
   Web::resetPrameter();
   
   return(true);
}


/**
 * Add HTTP request paramter to member variable params.
 * If key already exists, update the value.
 *
 * @params const string key  Name of the HTTP request paramter.
 * @params const string value  Value of the HTTP request parameter.
 */
static void Web::addParameter(const string key, const string value)
{
   int size = ArraySize(Web::params);
   for(int i = 0; i < size; i++) {
      if(Web::params[i].key == key) {
         Web::params[i].value = value;
         return;
      }
   }
   
   int new_size = size + 1;
   ArrayResize(Web::params, new_size, 0);
   
   Web::params[size].key = key;
   Web::params[size].value = value;
}


/** Reset member variable params. */
static void Web::resetPrameter(void)
{
   ArrayResize(Web::params, 0);
}


/**
 * HTTP request by GET.
 *
 * @param string url  URL.
 * @param string &response  Server response data.
 *
 * @return bool  Returns true if successful, otherwise flase.
 */
static bool Web::get(string url, string &response)
{
   char data[];
   for(int i = 0; i < ArraySize(Web::params); i++) {
      if(i == 0) url += "?";
      else       url += "&";
      
      url += Web::params[i].key;
      url += "=";
      url += Web::params[i].value;
   }
   
   return(Web::request(url, "GET", data, response));
}


/**
 * HTTP request by POST.
 *
 * @param string url  URL.
 * @param WebParameter &param[]  HTTP request parameters.
 * @param string &response  Server response data.
 *
 * @return bool  Returns true if successful, otherwise flase.
 */
static bool Web::post(string url, string &response)
{
   char data[];
   string post = "";
   for(int i = 0; i < ArraySize(Web::params); i++) {
      if(i != 0) post += "&";
      post += Web::params[i].key;
      post += "=";
      post += Web::params[i].value;
   }
   StringToCharArray(post, data);
   
   return(Web::request(url, "POST", data, response));
}


/**
 * Download and save the file.
 *
 * @param string url  Download file URL.
 * @param string path  File name to save.
 *
 * @return  Returns true if successful, otherwise flase.
 */
static bool Web::download(string url, string path)
{
   string command = "";
   string cmd     = "C:\\Windows\\System32\\cmd.exe";
   
   command  = "/c @powershell -NoProfile -ExecutionPolicy Bypass -Command";
   command += " \"$d=new-object System.Net.WebClient;";
   command += "$d.Proxy.Credentials=[System.Net.CredentialCache]";
   command += "::DefaultNetworkCredentials;";
   command += "$d.DownloadFile('";
   command += url;
   command += "', '";
   command += TerminalInfoString(TERMINAL_DATA_PATH);
   command += "\\MQL4\\Files\\" + path;
   command += "')\"";

   return(Shell32::ShellExecuteW(0, "open", cmd, command, "", 0) > 32);
}

#endif 
