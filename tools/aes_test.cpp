#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <string.h>
#include <openssl/rand.h>

#define PKCS5_SALT_LEN                  8
#define SIZE    (512)
#define BSIZE   (8*1024)
#define PROG_NAME_SIZE  39

void handleErrors(void)
{
  ERR_print_errors_fp(stderr);
  abort();
}


int encrypt(FILE *in, FILE *out, unsigned char *key, unsigned char *iv, const EVP_CIPHER* cipher, int enc)
{
  EVP_CIPHER_CTX *ctx;

  unsigned char inbuf[1024], outbuf[1024 + EVP_MAX_BLOCK_LENGTH];
  int inlen, outlen;

  /* Create and initialise the context */
  if(!(ctx = EVP_CIPHER_CTX_new())) handleErrors();

  /* Initialise the encryption operation. IMPORTANT - ensure you use a key
   * and IV size appropriate for your cipher
   * In this example we are using 256 bit AES (i.e. a 256 bit key). The
   * IV size for *most* modes is the same as the block size. For AES this
   * is 128 bits */
  if(!EVP_CipherInit_ex(ctx, cipher, NULL, NULL, NULL, enc))
          handleErrors();

    if (!EVP_CipherInit_ex(ctx, NULL, NULL, key, iv, enc)) 
        handleErrors();


  /* Provide the message to be encrypted, and obtain the encrypted output.
   * EVP_EncryptUpdate can be called multiple times if necessary
   */
    for(;;)
    {
        inlen = fread(inbuf, 1, 1024, in);
        if (inlen <= 0) break;
        if(!EVP_CipherUpdate(ctx, outbuf, &outlen, inbuf, inlen))
        {
            /* Error */
            EVP_CIPHER_CTX_free(ctx);
            return 0;
        }
        fwrite(outbuf, 1, outlen, out);
    }

    if(!EVP_CipherFinal_ex(ctx, outbuf, &outlen))
    {
        /* Error */
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    fwrite(outbuf, 1, outlen, out);

  /* Clean up */
  EVP_CIPHER_CTX_free(ctx);

  return 1;
}



size_t BUF_strlcpy(char *dst, const char *src, size_t size)
{
    size_t l = 0;
    for (; size > 1 && *src; size--) {
        *dst++ = *src++;
        l++;
    }
    if (size)
        *dst = '\0';
    return l + strlen(src);
}

void program_name(char *in, char *out, int size)
{
    char *p;

    p = strrchr(in, '/');
    if (p != NULL)
        p++;
    else
        p = in;
    BUF_strlcpy(out, p, size);
}

int set_hex(char *in, unsigned char *out, int size)
{
    int i, n;
    unsigned char j;

    n = strlen(in);
    if (n > (size * 2)) {
        return (0);
    }
    memset(out, 0, size);
    for (i = 0; i < n; i++) {
        j = (unsigned char)*in;
        *(in++) = '\0';
        if (j == 0)
            break;
        if ((j >= '0') && (j <= '9'))
            j -= '0';
        else if ((j >= 'A') && (j <= 'F'))
            j = j - 'A' + 10;
        else if ((j >= 'a') && (j <= 'f'))
            j = j - 'a' + 10;
        else {
            return (0);
        }
        if (i & 1)
            out[i / 2] |= j;
        else
            out[i / 2] = (j << 4);
    }
    return (1);
}

int main (int argc, char** argv)
{
    if (argc < 3)
        return -1;
    int enc = -1;

    static const char magic[] = "Salted__";
    char mbuf[sizeof magic - 1];
    argc--;
    argv++;
    if(strcmp(*argv, "-e") == 0)
    {
        printf("enc\n");
        enc = 1;
    } else if (strcmp(*argv, "-d") == 0)
    {
        enc = 0;
    }
    char* rpath = argv[2];
    char* wpath = argv[3];
    printf("rpath:%s\n", rpath);
    printf("wpath:%s\n", wpath);
    
    FILE* rfd = fopen (rpath, "rb");
    FILE* wfd = fopen(wpath, "wb");
  /* Set up the key and iv. Do I need to say to not hard code these in a
   * real application? :-)
   */

  /* A 256 bit key */
  unsigned char salt[PKCS5_SALT_LEN];
  unsigned char *sptr;
  char pname[PROG_NAME_SIZE + 1];
  //char *strbuf = NULL;
  const EVP_MD *dgst = NULL;
  const EVP_CIPHER *cipher = NULL, *c;
  program_name("enc", pname, sizeof pname);
  char* ciphername = "aes-256-cbc";

  //cipher = EVP_get_cipherbyname(pname);
  
  //if((c = EVP_get_cipherbyname("aes-256-ecb")) != NULL)
  //{
    //cipher = c;
  //}
  //cipher = EVP_get_cipherbyname("aes-256-cbc");
  cipher = EVP_aes_256_cbc();

  dgst = EVP_md5();
  //strbuf = OPENSSL_malloc(SIZE);

  unsigned char key[EVP_MAX_KEY_LENGTH], iv[EVP_MAX_IV_LENGTH];

  unsigned char* srcstr = new unsigned char[1024];
  unsigned char* desstr = new unsigned char[1024];
  /* Message to be encrypted */
  //unsigned char *plaintext = (unsigned char *)"The quick brown fox jumps over the lazy dog";

  /* Buffer for ciphertext. Ensure the buffer is long enough for the
   * ciphertext which may be longer than the plaintext, dependant on the
   * algorithm and mode
   */
  unsigned char ciphertext[128];

  /* Buffer for the decrypted text */
  unsigned char decryptedtext[128];

  /* Initialise the library */
  ERR_load_crypto_strings();
  OpenSSL_add_all_algorithms();
  OPENSSL_config(NULL);

  char* str = argv[1];

  /* Encrypt the plaintext */
  if(enc == 1)
  {
      if (RAND_bytes(salt, sizeof salt) <= 0)
          return -1;

      /*char* hsalt = argv[1];
      if (!set_hex(hsalt, salt, sizeof salt))
          return -1;
          */
      
      sptr = salt;

      EVP_BytesToKey(cipher, dgst, sptr, (unsigned char *)str, strlen(str), 1, key, iv);
      fwrite(magic, 1, sizeof magic - 1, wfd);
      fwrite(salt, 1, sizeof salt, wfd);
  }
  else if(enc == 0)
  {
      fread(mbuf, 1, sizeof mbuf, rfd);
      printf("mbuf:%s\n", mbuf);
      fread(salt, 1, sizeof salt, rfd);
      sptr = salt;
      EVP_BytesToKey(cipher, dgst, sptr, (unsigned char *)str, strlen(str), 1, key, iv);
  }

  encrypt (rfd, wfd, key, iv, cipher, enc);
#ifdef _DEBUG_KEY_
            printf("salt=");
            int i = 0;
            for (i = 0; i < (int)sizeof(salt); i++)
                printf("%02X", salt[i]);
            printf("\n");
            if (cipher->key_len > 0) {
                printf("key=");
                for (i = 0; i < cipher->key_len; i++)
                    printf("%02X", key[i]);
                printf("\n");
            }
            if (cipher->iv_len > 0) {
                printf("iv =");
                for (i = 0; i < cipher->iv_len; i++)
                    printf("%02X", iv[i]);
                printf("\n");
            }
#endif
  fclose(rfd);
  fclose(wfd);
  delete[] srcstr;
  delete[] desstr;

  /* Clean up */
  EVP_cleanup();
  ERR_free_strings();

  return 0;
}
